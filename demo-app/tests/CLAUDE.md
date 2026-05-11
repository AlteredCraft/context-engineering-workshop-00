# tests/CLAUDE.md

Implementation conventions for code in `tests/`. Loads on-demand when Claude reads a file in this directory.

## FakeFetcher injection (no `unittest.mock`)

`create_app()` accepts an optional `feed_fetcher` callable and stores it on `app.extensions["feed_fetcher"]`. Routes call `current_app.extensions["feed_fetcher"](url)`. Tests pass a `FakeFetcher` (defined in `conftest.py`) through this seam.

**Why this seam exists:** mocking `requests` or `feedparser` at module scope is fragile — it depends on import order and patches global state. The injected callable means each test owns its fetcher and there's nothing to "reset" between tests. When you add a fetch-dependent route, route the call through the same seam; do not import `requests`/`feedparser` directly in routes.

## Never mock the database

`TestConfig` sets `SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"`. Tests hit a real SQLite DB. Do not patch `db.session`, do not use `unittest.mock` against SQLAlchemy, do not stub out queries.

If a test needs a specific DB state, set it up by inserting real rows through the session — same way the app does in production paths.

## Fixtures (from `conftest.py`)

- `fake_fetcher` — fresh `FakeFetcher()` per test; call `fake_fetcher.set(parsed_feed)` before exercising a fetch path.
- `app` — Flask app constructed with `TestConfig` and the fake fetcher. Yields inside an `app_context()`; tears down by removing the session and dropping all tables.
- `client` — `app.test_client()`. Use this for HTTP-level integration tests.
- `db_session` — `db.session` inside an `app_context()`. Use when the test needs to query/insert directly rather than going through the client.

Compose these — `client + db_session + fake_fetcher` is the typical trio for an endpoint test.

## Test class organization

Existing tests in `test_feeds.py` group by route family (`TestAddFeed`, `TestListEntries`, `TestRefreshFeed`, `TestDeleteFeed`). Follow the same convention when adding new route tests; one class per route family, methods named `test_<scenario>`.
