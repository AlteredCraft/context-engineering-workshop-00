# Init Observations

Non-standard approaches noticed while inspecting the stack for CLAUDE.md.

## Dependency injection via `app.extensions`
`create_app(config_class=None, feed_fetcher=None)` stores the fetcher on `app.extensions["feed_fetcher"]` and routes call `current_app.extensions["feed_fetcher"](url)`. This is a deliberate seam so tests can pass a `FakeFetcher` without `unittest.mock`. Uncommon — most Flask apps would either import `requests`/`feedparser` at module scope and monkeypatch in tests, or wrap in a service class.

## DELETE tunneled through POST
`app/feeds/routes.py::delete_feed` is registered for both `DELETE` and `POST`, and POSTs are only accepted when the form contains `_method=DELETE` (otherwise returns a redirect tuple with 405). This is a hand-rolled method-override instead of using `werkzeug`/`Flask-Methodoverride`. Note: returning `(redirect, 405)` on method mismatch is unusual — a redirect response with a 405 status code is semantically odd.

## `db.create_all()` on every startup, no migrations
Schema is materialized inside `create_app()` via `db.create_all()`. There is no Alembic / Flask-Migrate. Fine for a teaching app, but means model changes need a manual DB wipe (`instance/rss_reader.db`).

## Late-import blueprint pattern
`app/feeds/__init__.py` defines `bp = Blueprint(...)` then does `from app.feeds import routes  # noqa` at the bottom to bind routes. Works, but relies on import-time side effects; not all Flask codebases do this — many register routes explicitly from the factory.

## Config module at repo root
`config.py` sits next to `app/` rather than inside the package. Both `app/__init__.py` and `tests/conftest.py` import it as a top-level module. This works because the repo root is on `sys.path` when running via `uv run`, but it couples the package to the layout.

## `FakeFetcher` test fixture builds entries with `type()` + monkey-patched `.get`
`tests/test_feeds.py::_make_parsed_feed` constructs feed entries with `type("E", (), e)()` and then assigns `entry_obj.get = entry_dict.get` so `.get("title")` works like on a real `feedparser` entry. This dodges needing a real `feedparser.FeedParserDict` but is fragile — any new attribute access in `_parse_entries` needs a matching key in the fixture dict.

## Non-timezone-aware `published_at`
`_parse_entries` builds `datetime.datetime(*time_struct[:6])` (naive) while `Feed.created_at` / `Entry.created_at` default to `datetime.datetime.now(datetime.UTC)` (aware). Mixing naive and aware datetimes in the same schema will bite if anyone starts comparing them.

## `Entry.feed` backref vs. explicit `feed=feed` kwarg
Routes create entries with `Entry(feed=feed, **entry_data)` — this relies on the SQLAlchemy `backref="feed"` on `Feed.entries` rather than setting `feed_id`. Works, just worth knowing the relationship is implicit.
