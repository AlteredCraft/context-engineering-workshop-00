import time

import pytest

from app.models import Entry, Feed


def _make_parsed_feed(title="Test Feed", entries=None):
    """Build a fake feedparser result."""
    if entries is None:
        entries = [
            {
                "title": "Entry 1",
                "link": "https://example.com/1",
                "published_parsed": time.strptime("2024-01-15", "%Y-%m-%d"),
            },
            {
                "title": "Entry 2",
                "link": "https://example.com/2",
                "published_parsed": time.strptime("2024-01-16", "%Y-%m-%d"),
            },
        ]

    class FakeFeed:
        pass

    parsed = FakeFeed()
    parsed.feed = {"title": title}
    parsed.entries = [type("E", (), e)() for e in entries]

    # Make entries support .get()
    for entry_obj, entry_dict in zip(parsed.entries, entries):
        entry_obj.get = entry_dict.get

    return parsed


class TestAddFeed:
    def test_add_feed_creates_feed_and_entries(self, client, db_session, fake_fetcher):
        fake_fetcher.set(_make_parsed_feed())

        response = client.post(
            "/feeds", data={"url": "https://example.com/feed.xml"}
        )

        assert response.status_code == 302
        feed = db_session.query(Feed).first()
        assert feed is not None
        assert feed.title == "Test Feed"
        assert feed.url == "https://example.com/feed.xml"
        assert len(feed.entries) == 2

    def test_add_feed_with_no_title_uses_url(self, client, db_session, fake_fetcher):
        fake_fetcher.set(_make_parsed_feed(title=None))

        client.post("/feeds", data={"url": "https://example.com/notitle.xml"})

        feed = db_session.query(Feed).first()
        assert feed.title == "https://example.com/notitle.xml"

    def test_add_duplicate_feed_url_fails(self, client, db_session, fake_fetcher):
        fake_fetcher.set(_make_parsed_feed())

        client.post("/feeds", data={"url": "https://example.com/feed.xml"})

        with pytest.raises(Exception):
            client.post("/feeds", data={"url": "https://example.com/feed.xml"})


class TestListEntries:
    def test_show_feed_lists_entries(self, client, db_session, fake_fetcher):
        fake_fetcher.set(_make_parsed_feed())

        client.post("/feeds", data={"url": "https://example.com/feed.xml"})
        feed = db_session.query(Feed).first()

        response = client.get(f"/feeds/{feed.id}")
        assert response.status_code == 200
        assert b"Entry 1" in response.data
        assert b"Entry 2" in response.data

    def test_show_feed_returns_404_for_missing(self, client):
        response = client.get("/feeds/999")
        assert response.status_code == 404

    def test_index_shows_feeds_with_counts(self, client, db_session, fake_fetcher):
        fake_fetcher.set(_make_parsed_feed())

        client.post("/feeds", data={"url": "https://example.com/feed.xml"})

        response = client.get("/")
        assert response.status_code == 200
        assert b"Test Feed" in response.data


class TestRefreshFeed:
    def test_refresh_adds_new_entries(self, client, db_session, fake_fetcher):
        fake_fetcher.set(_make_parsed_feed())
        client.post("/feeds", data={"url": "https://example.com/feed.xml"})
        feed = db_session.query(Feed).first()
        assert len(feed.entries) == 2

        # Refresh with one new entry added
        fake_fetcher.set(_make_parsed_feed(entries=[
            {
                "title": "Entry 1",
                "link": "https://example.com/1",
                "published_parsed": time.strptime("2024-01-15", "%Y-%m-%d"),
            },
            {
                "title": "Entry 2",
                "link": "https://example.com/2",
                "published_parsed": time.strptime("2024-01-16", "%Y-%m-%d"),
            },
            {
                "title": "Entry 3",
                "link": "https://example.com/3",
                "published_parsed": time.strptime("2024-01-17", "%Y-%m-%d"),
            },
        ]))

        response = client.post(f"/feeds/{feed.id}/refresh")
        assert response.status_code == 302

        entries = db_session.query(Entry).filter_by(feed_id=feed.id).all()
        assert len(entries) == 3


class TestDeleteFeed:
    def test_delete_feed_removes_feed_and_entries(self, client, db_session, fake_fetcher):
        fake_fetcher.set(_make_parsed_feed())

        client.post("/feeds", data={"url": "https://example.com/feed.xml"})
        feed = db_session.query(Feed).first()
        feed_id = feed.id

        response = client.post(
            f"/feeds/{feed_id}",
            data={"_method": "DELETE"},
        )
        assert response.status_code == 302

        assert db_session.get(Feed, feed_id) is None
        assert db_session.query(Entry).filter_by(feed_id=feed_id).count() == 0

    def test_delete_missing_feed_returns_404(self, client):
        response = client.post("/feeds/999", data={"_method": "DELETE"})
        assert response.status_code == 404
