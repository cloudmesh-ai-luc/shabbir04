# InferScale

**One ML inference service on three clouds, deployed with `cmx vm`.** InferScale serves a sentiment-analysis
model (DistilBERT) through a FastAPI REST API and a small web page, keeps each user's history in PostgreSQL,
and runs the same three containers on **Multipass** (local), **Jetstream** (OpenStack) and **AWS EC2**
(public cloud). Khaja Shabbir Ahmed, COMP 488 Cloud Computing, DevOps and AI, Loyola University Chicago, Fall 2026.

- **The full report:** [Project](project/project.md): design, security, deployment, monitoring and results
- **Code:** [github.com/cloudmesh-ai-luc/shabbir04](https://github.com/cloudmesh-ai-luc/shabbir04)
- **Weekly assignments:** [assignments/](https://github.com/cloudmesh-ai-luc/shabbir04/tree/main/assignments)

## What it does

| Part | How |
| ---- | --- |
| Three tiers in containers | `web` (nginx: HTTPS, login, rate limit, the page) → `api` (FastAPI + DistilBERT) → `db` (PostgreSQL 16) |
| One command per step on any cloud | `make deploy`, `start`, `demo`, `load`, `stop`, `destroy` with `CLOUD=multipass`, `jetstream` or `aws` |
| Security | HTTPS only, a login for every call, bcrypt password hashes, no public port for the API or the database, containers that do not run as root, no secrets in Git |
| CI on every push | Tests on Python 3.15.2, pip-audit, gitleaks, hadolint, image build and Trivy |
| Monitoring | Prometheus + Grafana for all clouds, with `CloudDown` and `HighErrorRate` alerts |
| Failover | `tools/client.py` sends each request to AWS, then Jetstream, then Multipass, until one answers |

## Results (Nov 27)

| Cloud | Median response | p95 | Failed requests |
| ----- | --------------- | --- | --------------- |
| Multipass | 31 ms | 73 ms | 0 |
| Jetstream | 99 ms | 210 ms | 0 |
| AWS | 140 ms | 290 ms | 0 |

4,706 requests in nine load-test runs, none failed. With AWS taken down halfway, 200 of 200 requests
still succeeded through Jetstream, and the `CloudDown` alert fired after 51 seconds.
The details are in the [report](project/project.md#results-nov-27).
