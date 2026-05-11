# CLAUDE.md

IMPORTANT: Before assisting the user, run `date '+%A %Y-%m-%d %H:%M:%S %z %Z'` so you have the current date/time.

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

See @README.md for project overview, stack, setup, and layout.

## Commands

- Run app: `uv run flask --app app run`
- Run tests: `uv run pytest`
- Single test: `uv run pytest tests/test_feeds.py::TestAddFeed::test_add_feed_creates_feed_and_entries`

## Architecture notes

- **App factory + injectable fetcher.** `create_app()` in `app/__init__.py` accepts an optional `feed_fetcher` callable and stores it on `app.extensions["feed_fetcher"]`. Routes call `current_app.extensions["feed_fetcher"](url)` rather than importing `requests`/`feedparser` directly. Tests pass a `FakeFetcher` through this seam instead of mocking — keep this pattern when adding fetch-dependent code.
- **No migrations.** `db.create_all()` runs inside `create_app()` on every startup. Model changes require dropping `instance/rss_reader.db` (dev) — no Alembic.
- **DELETE-over-POST.** `delete_feed` accepts POST with a form field `_method=DELETE` (no Flask-Methodoverride). Preserve this when adding similar destructive routes or HTML forms.
- **Entry de-dup** on refresh is done in Python by comparing `link` against existing entries for the feed; there is also a `UniqueConstraint(feed_id, link)` in `app/models.py`.
- **Blueprint wiring** uses the late-import pattern: `app/feeds/__init__.py` defines `bp` then imports `routes` at the bottom. Register new routes by adding them to `app/feeds/routes.py`, not a new module, unless you also update `__init__.py`.
- **Config lives at repo root** (`config.py`), not inside `app/`. `TestConfig` uses `sqlite:///:memory:` — tests hit real SQLite, never a mock.

## Testing

- **Every new endpoint ships with integration tests** covering the happy path plus at least one error path. This is a team requirement, independent of personal test-first or test-after preference.
- See `tests/CLAUDE.md` for test implementation conventions (fixtures, the `FakeFetcher` injection seam, and the rule against mocking the database).

## Code style

- **Type hints use Python 3.10+ syntax.** Write `list[str]`, `dict[str, int]`, `str | None`. Do NOT import `Optional`, `List`, `Dict`, or `Union` from `typing` — the built-in generics and `|` union are preferred in all new code.
