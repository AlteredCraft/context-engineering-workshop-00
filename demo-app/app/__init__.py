import datetime

from flask import Flask
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


def create_app(config_class: type | None = None, feed_fetcher=None) -> Flask:
    if config_class is None:
        from config import Config
        config_class = Config

    app = Flask(__name__)
    app.config.from_object(config_class)

    db.init_app(app)

    from app.feeds.routes import default_fetch_feed
    app.extensions["feed_fetcher"] = feed_fetcher or default_fetch_feed

    from app.feeds import bp as feeds_bp
    app.register_blueprint(feeds_bp)

    @app.context_processor
    def inject_now():
        return {"now": datetime.datetime.now}

    with app.app_context():
        db.create_all()

    return app
