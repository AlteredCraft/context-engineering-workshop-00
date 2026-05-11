import pytest

from app import create_app, db as _db
from config import TestConfig


class FakeFetcher:
    def __init__(self):
        self.parsed = None
        self.calls = []

    def set(self, parsed):
        self.parsed = parsed

    def __call__(self, url):
        self.calls.append(url)
        return self.parsed


@pytest.fixture
def fake_fetcher():
    return FakeFetcher()


@pytest.fixture
def app(fake_fetcher):
    app = create_app(TestConfig, feed_fetcher=fake_fetcher)
    with app.app_context():
        yield app
        _db.session.remove()
        _db.drop_all()


@pytest.fixture
def client(app):
    return app.test_client()


@pytest.fixture
def db_session(app):
    with app.app_context():
        yield _db.session
