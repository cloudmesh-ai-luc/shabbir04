"""Load test for InferScale (Locust): users send reviews to /api/predict and sometimes open their history,
through HTTPS and the login, like the web page does.

make load CLOUD=<cloud> runs it against one deployed cloud and saves the results in results/<cloud>/.
By hand:  CLOUD=jetstream locust -f tools/loadtest.py --headless -u 10 -r 2 -t 60s --host https://<ip>

Ten users with a pause of 0.5 to 1.5 seconds send about 10 requests per second, below nginx's limit of
50 per second, so the test measures the service and not the rate limit.
"""
import os
import random
from pathlib import Path

from locust import HttpUser, between, task

CONFIG = Path.home() / ".config" / "inferscale"   # outside Git
CLOUD = os.environ.get("CLOUD", "multipass")

REVIEWS = [
    "The battery lasts all day and the screen is beautiful.",
    "It stopped working after two days and support never answered.",
    "Great value for the price, I would buy it again.",
    "The package arrived late and the box was damaged.",
    "Setup took five minutes and everything worked right away.",
    "The sound is tinny and the volume buttons feel cheap.",
    "Comfortable to wear for hours, even on long flights.",
    "Not worth the money, the cheaper model is better.",
]


class Reviewer(HttpUser):
    wait_time = between(0.5, 1.5)

    def on_start(self):
        self.client.verify = str(CONFIG / "certs" / f"{CLOUD}.pem")   # this cloud's own certificate
        self.client.auth = ("client", (CONFIG / "client.password").read_text().strip())

    @task(5)
    def predict(self):
        self.client.post("/api/predict", json={"text": random.choice(REVIEWS)}, name="/api/predict")

    @task(1)
    def history(self):
        self.client.get("/api/history?limit=20", name="/api/history")
