# claude-md-lesson-00

A minimal Flask RSS feed reader. Users add RSS feed URLs, the app fetches and
parses each feed with `feedparser`, and entries are stored in SQLite. A simple
web UI lists feeds and their entries (newest first), with a refresh action that
re-fetches a feed and upserts new entries.

Built as a teaching testbed for
[Lightning Lesson 1: Build the CLAUDE.md Your Project Needs](https://maven.com/altered-craft-learning).
The goal is a real-but-small app — small enough to fit in a 30-minute lesson,
real enough that a project-level `CLAUDE.md` earns its keep.

## Stack

- Python 3.12+
- Flask 3.x (app factory pattern in `app/__init__.py`)
- Flask-SQLAlchemy + SQLite
- `feedparser` for RSS/Atom parsing
- `uv` for dependency management
- `pytest` for integration tests (in-memory SQLite via `TestConfig`)

## Setup

```bash
uv sync
uv run flask --app app run
```

Then visit http://localhost:5000.

## Tests

```bash
uv run pytest
```

Tests hit a real in-memory SQLite database through `TestConfig` — the DB is
never mocked, and no test DB file is created on disk.

## Project layout

```
app/
├── __init__.py       # create_app() factory, db init, blueprint registration
├── models.py         # Feed + Entry models
├── feeds/            # Feeds blueprint (list, add, show, refresh, delete)
└── templates/        # Jinja templates (base, index, feed_detail)
tests/                # Integration tests using in-memory SQLite
config.py             # Config + TestConfig
```
