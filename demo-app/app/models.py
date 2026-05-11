import datetime

from app import db


class Feed(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    url = db.Column(db.String(500), unique=True, nullable=False)
    created_at = db.Column(
        db.DateTime, default=lambda: datetime.datetime.now(datetime.UTC)
    )

    entries = db.relationship(
        "Entry", backref="feed", cascade="all, delete-orphan", lazy=True
    )


class Entry(db.Model):
    __table_args__ = (db.UniqueConstraint("feed_id", "link"),)

    id = db.Column(db.Integer, primary_key=True)
    feed_id = db.Column(db.Integer, db.ForeignKey("feed.id"), nullable=False)
    title = db.Column(db.String(300), nullable=False)
    link = db.Column(db.String(500), nullable=False)
    published_at = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(
        db.DateTime, default=lambda: datetime.datetime.now(datetime.UTC)
    )
