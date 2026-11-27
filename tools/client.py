"""Failover client for InferScale: each request goes to the first cloud that answers.

The clouds are tried in the order AWS, Jetstream, Multipass. The deployed ones are read from
~/.config/inferscale/clouds/<cloud>.env (written by make deploy); each cloud's own certificate
(~/.config/inferscale/certs/<cloud>.pem) is checked, and the client account logs in. After a cloud
fails, it is skipped for 30 seconds (a simple circuit breaker), so a dead cloud does not slow every
request down with a timeout.

    python tools/client.py "The battery lasts all day"   # one prediction
    python tools/client.py --demo 200                      # 200 predictions and a summary
"""
import argparse
import base64
import json
import ssl
import sys
import time
import urllib.error
import urllib.request
from collections import Counter
from pathlib import Path

CONFIG = Path.home() / ".config" / "inferscale"   # outside Git
ORDER = ["aws", "jetstream", "multipass"]
TIMEOUT = 3      # seconds to wait for one cloud
COOLDOWN = 30    # seconds to skip a cloud after it failed


class Cloud:
    def __init__(self, name):
        state = dict(line.split("=", 1) for line in (CONFIG / "clouds" / f"{name}.env").read_text().split())
        self.name = name
        self.url = f"https://{state['IP']}/api"
        self.tls = ssl.create_default_context(cafile=str(CONFIG / "certs" / f"{name}.pem"))
        self.down_until = 0.0


def deployed_clouds():
    names = [n for n in ORDER if (CONFIG / "clouds" / f"{n}.env").exists() and (CONFIG / "certs" / f"{n}.pem").exists()]
    return [Cloud(n) for n in names]


def login_header():
    password = (CONFIG / "client.password").read_text().strip()
    return "Basic " + base64.b64encode(f"client:{password}".encode()).decode()


def predict(text, clouds, login):
    """Return (cloud name, answer) from the first cloud that answers."""
    now = time.monotonic()
    for cloud in clouds:
        if cloud.down_until > now:
            continue   # failed recently: skip it for now
        request = urllib.request.Request(
            f"{cloud.url}/predict", data=json.dumps({"text": text}).encode(),
            headers={"Content-Type": "application/json", "Authorization": login})
        try:
            with urllib.request.urlopen(request, timeout=TIMEOUT, context=cloud.tls) as response:
                return cloud.name, json.load(response)
        except OSError:   # no answer, refused, TLS error or an HTTP error such as 502 from nginx
            cloud.down_until = now + COOLDOWN
    raise RuntimeError("all clouds are down")


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("text", nargs="?", help="a review to analyze")
    parser.add_argument("--demo", type=int, metavar="N", help="send N predictions and print a summary")
    args = parser.parse_args()

    clouds = deployed_clouds()
    if not clouds:
        sys.exit("No deployed cloud: run make deploy and make start first")
    print("Clouds in order:", ", ".join(c.name for c in clouds))
    login = login_header()

    if not args.demo:
        cloud, answer = predict(args.text or "The battery lasts all day.", clouds, login)
        print(f"{cloud}: {answer}")
        return

    answered, failed, previous = Counter(), 0, None
    for i in range(1, args.demo + 1):
        try:
            cloud, _ = predict(f"Review number {i}: the product works well.", clouds, login)
            answered[cloud] += 1
            if cloud != previous:
                print(f"request {i}: answered by {cloud}")
                previous = cloud
        except RuntimeError:
            failed += 1
            print(f"request {i}: all clouds are down")
        time.sleep(0.25)
    total = args.demo
    print(f"\n{total - failed} of {total} requests answered ({100 * (total - failed) / total:.1f} %):",
          ", ".join(f"{c} {n}" for c, n in answered.items()) or "none")


if __name__ == "__main__":
    main()
