# src/inferscale/app.py
import asyncio
import os
from contextlib import asynccontextmanager
from functools import lru_cache
from typing import Literal

import psycopg
from fastapi import Depends, FastAPI, Header, HTTPException, Query
from pydantic import BaseModel, Field
from prometheus_fastapi_instrumentator import Instrumentator
from transformers import pipeline

MODEL = "distilbert/distilbert-base-uncased-finetuned-sst-2-english"
# the password comes from /etc/inferscale/db.env on the VM, never from Git
DB_URL = f"postgresql://inferscale:{os.environ.get('POSTGRES_PASSWORD', '')}@db:5432/inferscale"
SCHEMA = """CREATE TABLE IF NOT EXISTS predictions (
    id SERIAL PRIMARY KEY, created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    account TEXT NOT NULL, text TEXT NOT NULL, label TEXT NOT NULL, score REAL NOT NULL)"""

@lru_cache
def get_classifier():
    return pipeline("sentiment-analysis", model=MODEL)   # loaded once, then reused

def get_db():
    try:
        conn = psycopg.connect(DB_URL, connect_timeout=3)
    except psycopg.OperationalError:
        raise HTTPException(503, "database not available")
    with conn:                                           # commits when the request ends
        yield conn

@asynccontextmanager
async def lifespan(app):
    for _ in range(30):                                  # wait up to 30 s for the db container
        try:
            with psycopg.connect(DB_URL) as conn:
                conn.execute(SCHEMA)
            break
        except psycopg.OperationalError:
            await asyncio.sleep(1)
    get_classifier()                                     # load the model at start-up
    yield

app = FastAPI(lifespan=lifespan)
Instrumentator().instrument(app).expose(app)             # adds GET /metrics

class Review(BaseModel):
    text: str = Field(min_length=1, max_length=5000)
    min_score: float | None = Field(None, ge=0, le=1)   # optional: below it the label is UNCERTAIN

class Reviews(BaseModel):
    texts: list[str] = Field(min_length=1, max_length=100)
    label: Literal["POSITIVE", "NEGATIVE"] = "NEGATIVE"
    min_score: float = Field(0.9, ge=0, le=1)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/predict")
def predict(item: Review, user: str = Header("unknown", alias="X-User"),
            classifier=Depends(get_classifier), db=Depends(get_db)):
    result = classifier(item.text, truncation=True)[0]  # e.g. {"label": "POSITIVE", "score": 0.99}
    if item.min_score is not None and result["score"] < item.min_score:
        result = {"label": "UNCERTAIN", "score": result["score"]}      # not confident enough
    db.execute("INSERT INTO predictions (account, text, label, score) VALUES (%s, %s, %s, %s)",
               (user, item.text, result["label"], result["score"]))   # parameters, not joined text
    return result

@app.post("/filter")
def filter_reviews(item: Reviews, classifier=Depends(get_classifier)):
    # only the confident reviews with the chosen label, e.g. the confident negative ones
    results = classifier(item.texts, truncation=True)
    return [{"text": t, **r} for t, r in zip(item.texts, results)
            if r["label"] == item.label and r["score"] >= item.min_score]

@app.get("/history")
def history(limit: int = Query(20, ge=1, le=100), user: str = Header("unknown", alias="X-User"),
            db=Depends(get_db)):
    rows = db.execute("SELECT created_at, text, label, score FROM predictions "
                      "WHERE account = %s ORDER BY id DESC LIMIT %s", (user, limit)).fetchall()
    return [{"time": created.isoformat(), "text": text, "label": label, "score": score}
            for created, text, label, score in rows]
