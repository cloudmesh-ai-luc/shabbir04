"""Ask the Jetstream LLM how to improve docs/project/project.md (assignment 10/29, part d).

Usage (in your own terminal; the token is never written to a file):
    read -s 'JETSTREAM_API_TOKEN?Token: '; export JETSTREAM_API_TOKEN
        # token from https://llm.jetstream-cloud.org: profile icon -> Settings -> Account -> API keys
    python tools/llm_review.py                # lists the models you can use
    python tools/llm_review.py <model>        # writes llm-review.md
"""
import json
import os
import sys
import urllib.error
import urllib.request
from datetime import date

BASE = "https://llm.jetstream-cloud.org/api"  # Open WebUI gateway
PROMPT = (
    "You are reviewing a student's cloud computing project plan. Suggest concrete improvements "
    "to its design, security, testing, DevOps and AI parts. Give at most 10 suggestions. For each one, "
    "name the section it applies to, what to change, and why. Do not repeat what the plan already does.\n\n"
)


def call(path, payload=None):
    key = os.environ.get("JETSTREAM_API_TOKEN", "").strip()
    if not key:
        sys.exit("Set your token first: read -s 'JETSTREAM_API_TOKEN?Token: '; export JETSTREAM_API_TOKEN")
    req = urllib.request.Request(
        BASE + path,
        data=json.dumps(payload).encode() if payload else None,
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        if e.code == 401:
            sys.exit("401: the token was not accepted. Create a new one at https://llm.jetstream-cloud.org.")
        sys.exit(f"{e.code}: {e.read().decode(errors='replace')[:300]}")


if len(sys.argv) < 2:
    print("Available models:")
    for m in call("/models").get("data", []):
        print("  ", m["id"])
    sys.exit("Run again with one of them: python tools/llm_review.py <model>")

model = sys.argv[1]
plan = open("docs/project/project.md", encoding="utf-8").read()
answer = call("/chat/completions", {
    "model": model,
    "messages": [{"role": "user", "content": PROMPT + plan}],
    "max_tokens": 2000,
    "temperature": 0.3,
})["choices"][0]["message"]["content"]

with open("llm-review.md", "w", encoding="utf-8") as f:
    f.write(f"# Jetstream LLM review of project.md\n\nModel: `{model}`, {date.today()}\n\n{answer}\n")
print("Saved llm-review.md")
