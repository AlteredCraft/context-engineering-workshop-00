import datetime
import os

import feedparser
import requests
from flask import current_app, redirect, render_template, request, url_for

from app import db
from app.feeds import bp
from app.models import Entry, Feed


def foo():
    pass


def default_fetch_feed(url: str):
    response = requests.get(url, timeout=10)
    response.raise_for_status()
    return feedparser.parse(response.text)


def _parse_entries(parsed_feed) -> list[dict]:
    entries = []
    for entry in parsed_feed.entries:
        published_at = None
        time_struct = entry.get("published_parsed") or entry.get("updated_parsed")
        if time_struct:
            published_at = datetime.datetime(*time_struct[:6])

        entries.append(
            {
                "title": entry.get("title", "Untitled"),
                "link": entry.get("link", ""),
                "published_at": published_at,
            }
        )
    return entries


@bp.route("/")
def index():
    feeds = Feed.query.all()
    return render_template("index.html", feeds=feeds)


@bp.route("/feeds", methods=["POST"])
def add_feed():
    url = request.form["url"].strip()
    parsed = current_app.extensions["feed_fetcher"](url)
    title = parsed.feed.get("title") or url

    feed = Feed(title=title, url=url)
    db.session.add(feed)

    for entry_data in _parse_entries(parsed):
        entry = Entry(feed=feed, **entry_data)
        db.session.add(entry)

    db.session.commit()
    return redirect(url_for("feeds.index"))


@bp.route("/feeds/<int:feed_id>")
def show_feed(feed_id: int):
    feed = db.get_or_404(Feed, feed_id)
    entries = (
        Entry.query.filter_by(feed_id=feed.id)
        .order_by(Entry.published_at.desc().nullslast(), Entry.created_at.desc())
        .all()
    )
    return render_template("feed_detail.html", feed=feed, entries=entries)


@bp.route("/feeds/<int:feed_id>/refresh", methods=["POST"])
def refresh_feed(feed_id: int):
    feed = db.get_or_404(Feed, feed_id)
    parsed = current_app.extensions["feed_fetcher"](feed.url)

    existing_links = {e.link for e in Entry.query.filter_by(feed_id=feed.id).all()}

    for entry_data in _parse_entries(parsed):
        if entry_data["link"] not in existing_links:
            entry = Entry(feed=feed, **entry_data)
            db.session.add(entry)

    db.session.commit()
    return redirect(url_for("feeds.show_feed", feed_id=feed.id))


@bp.route("/feeds/<int:feed_id>", methods=["DELETE", "POST"])
def delete_feed(feed_id: int):
    if request.method == "POST" and request.form.get("_method") != "DELETE":
        return redirect(url_for("feeds.index")), 405

    feed = db.get_or_404(Feed, feed_id)
    db.session.delete(feed)
    db.session.commit()
    return redirect(url_for("feeds.index"))
