"""Unit tests for the InferScale API. The model and the database are replaced by fakes."""
import datetime

from fastapi.testclient import TestClient

from inferscale import app as appmod
from inferscale.app import app, get_classifier, get_db


def fake_classifier(texts, truncation=True):
    many = isinstance(texts, list)
    out = [{"label": "NEGATIVE" if "bad" in t else "POSITIVE", "score": 0.95}
           for t in (texts if many else [texts])]
    return out if many else out[:1]


class FakeDB:
    """Keeps rows in a list and answers the two queries the API uses."""

    def __init__(self):
        self.rows = []
        self._last = []

    def execute(self, sql, params=()):
        if sql.startswith("INSERT"):
            self.rows.append((datetime.datetime(2026, 11, 1), *params))
        elif sql.startswith("SELECT"):
            user, limit = params
            self._last = [(t, x, label, s) for (t, a, x, label, s) in reversed(self.rows) if a == user][:limit]
        return self

    def fetchall(self):
        return self._last


db = FakeDB()
app.dependency_overrides[get_classifier] = lambda: fake_classifier
app.dependency_overrides[get_db] = lambda: db
client = TestClient(app)


def test_health():
    assert client.get("/health").json() == {"status": "ok"}


def test_predict_is_saved_and_history_shows_only_own_reviews():
    r = client.post("/predict", json={"text": "good film"}, headers={"X-User": "demo"})
    assert r.status_code == 200 and r.json()["label"] == "POSITIVE"
    client.post("/predict", json={"text": "bad film"}, headers={"X-User": "owner"})
    history = client.get("/history", headers={"X-User": "demo"}).json()
    assert [h["text"] for h in history] == ["good film"]


def test_predict_is_uncertain_below_min_score():
    r = client.post("/predict", json={"text": "good film", "min_score": 0.99})
    assert r.json() == {"label": "UNCERTAIN", "score": 0.95}
    r = client.post("/predict", json={"text": "good film", "min_score": 0.9})
    assert r.json()["label"] == "POSITIVE"


def test_bad_input_is_rejected():
    assert client.post("/predict", json={"text": ""}).status_code == 422
    assert client.post("/filter", json={"texts": ["ok"], "label": "HAPPY"}).status_code == 422
    assert client.get("/history?limit=0").status_code == 422
    assert client.post("/predict", json={"text": "ok", "min_score": 2}).status_code == 422


def test_filter_keeps_only_the_chosen_label():
    r = client.post("/filter", json={"texts": ["good", "bad"], "label": "NEGATIVE"})
    assert [x["text"] for x in r.json()] == ["bad"]


def test_database_down_gives_503():
    del app.dependency_overrides[get_db]
    old = appmod.DB_URL
    appmod.DB_URL = "postgresql://nobody:x@127.0.0.1:1/none"
    try:
        assert client.get("/history").status_code == 503
    finally:
        appmod.DB_URL = old
        app.dependency_overrides[get_db] = lambda: db
