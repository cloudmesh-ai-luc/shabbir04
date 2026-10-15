# InferScale: One ML Inference Service on Three Clouds with cmx vm

|                  |                                                                  |
| ---------------- | ---------------------------------------------------------------- |
| **Course:**      | COMP 488 – Cloud Computing, DevOps, and AI                       |
| **Team Members** | - *Khaja Shabbir Ahmed* – Cloud / DevOps Engineer (solo project) |
| **Contact**      | <kahmed5@luc.edu>                                                |
| **Instructor**   | Gregor von Laszewski                                             |
| **Repository**   | https://github.com/cloudmesh-ai-luc/shabbir04                    |
| **Date**         | *Sep. 22, 2026*                                                  |

---

## 1. Executive Summary

**Problem.** The same AI service often has to run on more than one cloud, but every cloud has its own
way to create VMs, give them a public IP and clean them up. That makes deployments hard to repeat and
clouds hard to compare fairly.

**What InferScale does.** InferScale is a small machine-learning inference service: a sentiment-analysis
model (DistilBERT) behind a FastAPI REST API, packaged as one Docker image. The same image runs on three
clouds: **Multipass** on my laptop (local), **Chameleon KVM@TACC** (OpenStack) and **AWS EC2** (public
cloud). All VMs are created, reached and deleted with one tool, **`cmx vm`** from the class project
[cloudmesh-ai-vm](https://github.com/cloudmesh-ai/cloudmesh-ai-vm), which I also contribute to. One
deploy script runs the same steps on every cloud, and a load test measures how each cloud performs.
On top of plain predictions, InferScale has three features: an **AI review filter**, **live monitoring**
of all three clouds, and **multi-cloud failover**.

**Result.** A repeatable, automated workflow and a side-by-side comparison of deployment time, response
time and cost on the three clouds. Where `cmx vm` falls short for this workflow, I fix it in small pull
requests (for example the `cmx vm ip` command, [#66](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/66)).

---

## 2. Cloud Computing, DevOps, and AI

| Area | How InferScale addresses it |
| ---- | --------------------------- |
| **Cloud Computing** | Runs the same service as VMs (IaaS) on three different kinds of cloud: a local hypervisor, an OpenStack research cloud and a public cloud. Uses each cloud's networking (local IP, floating IP, public IP), security groups, Chameleon leases, and compares cost. `cmx vm` hides the differences behind one command line. **Feature: multi-cloud failover.** When one cloud is down, requests go to the next cloud. |
| **DevOps** | GitHub flow (branches, pull requests, issues), automated tests and Docker builds with GitHub Actions, a container registry, one deploy script for all clouds, a smoke test after every deployment, and clean-up so nothing keeps running. **Feature: live monitoring.** Every VM reports its requests, errors and response time, and one screen shows all three clouds. |
| **AI** | The workload is an AI model: DistilBERT sentiment analysis served for inference on CPU. The project measures how fast that model answers on each cloud. **Feature: review filter.** The model returns only the reviews with a chosen label (for example, negative) that it is confident about. |

---

## 3. Objectives & Success Criteria

| # | Objective | Success criterion |
| - | --------- | ----------------- |
| 1 | Package the inference service as a Docker image | `/health` and `/predict` pass the tests; the image is built by CI |
| 2 | Run the service on three clouds using `cmx vm` for all VM management | `/predict` answers on Multipass, Chameleon and AWS |
| 3 | Automate the deployment | `./deploy.sh <cloud>` goes from no VM to a working service with one command |
| 4 | Measure and compare the clouds | A results table with deploy time, latency (p50/p95), success rate and cost per cloud |
| 5 | Improve `cmx vm` where the project needs it | Small, reviewed pull requests to cloudmesh-ai-vm |
| 6 | AI review filter | `/filter` returns only the reviews with the chosen label and a score at or above the threshold |
| 7 | Live monitoring | `monitor.py` shows requests, errors and average response time for all three clouds, refreshed every 5 seconds |
| 8 | Multi-cloud failover | With one cloud's VM deleted during a test run, requests still succeed through the other clouds |

---

## 4. Scope

| In scope | Out of scope |
| -------- | ------------ |
| Inference service (FastAPI + DistilBERT) and its Docker image | Training or fine-tuning models |
| Three clouds: Multipass, Chameleon KVM@TACC, AWS EC2 | Kubernetes and autoscaling (dropped to keep the project simple) |
| Deploy script built on `cmx vm` | GPUs |
| CI with GitHub Actions | High availability and production monitoring |
| Load test and comparison of the three clouds | Other public clouds (Azure, GCP) |
| Small fixes to `cmx vm` | A load balancer in front of the clouds (failover is done in the client) |
| Three features: review filter, live monitoring, multi-cloud failover | Monitoring dashboards such as Prometheus/Grafana (a simple terminal monitor is enough) |

---

## 5. Technical Approach

### 5.1 Architecture

```mermaid
flowchart LR
    GH[GitHub repo] -->|push| CI[GitHub Actions<br/>test + build image]
    CI -->|push image| REG[(GitHub Container Registry)]
    subgraph LAPTOP[My laptop]
        DEP[deploy.sh] --> CMX[cmx vm]
        CL[client.py failover<br/>monitor.py<br/>Locust load test]
    end
    CMX -->|start / run / delete| MP[Multipass VM<br/>local]
    CMX -->|start / ip assign / run / delete| CH[Chameleon KVM@TACC VM<br/>OpenStack]
    CMX -->|start / run / delete| AWS[AWS EC2 VM<br/>public cloud]
    REG -. docker pull .-> MP
    REG -. docker pull .-> CH
    REG -. docker pull .-> AWS
    CL -->|HTTP :8000| MP
    CL -->|HTTP :8000| CH
    CL -->|HTTP :8000| AWS
```

| Component | Technology | Notes |
| --------- | ---------- | ----- |
| Inference API | Python, FastAPI, Hugging Face Transformers | Endpoints `GET /health`, `POST /predict`, `POST /filter`, `GET /stats` |
| Monitoring | `monitor.py` | Reads `/stats` from all three clouds every 5 seconds and prints one table |
| Failover client | `client.py` | Sends each request to AWS, then Chameleon, then Multipass, until one answers |
| Container | Docker, GitHub Container Registry | Image `ghcr.io/shabbir04/inferscale` |
| VM management | `cmx vm` (cloudmesh-ai-vm, `dev2` branch) | The only tool used to create, reach and delete VMs |
| Deployment | `deploy.sh` | Runs the same `cmx vm` steps on each cloud |
| Load test | Locust | Runs from my laptop against each cloud |

### 5.2 Three Clouds and cmx vm

**Why these three.** Multipass is free and fast for development. Chameleon KVM@TACC is the class
OpenStack cloud (project CH-817419). AWS is the most widely used public cloud, and new accounts get
Free plan credits.

| | Local | OpenStack | Public |
| - | ----- | --------- | ------ |
| **Cloud** | Multipass on my Mac | Chameleon KVM@TACC | AWS EC2 |
| **`cmx vm` provider** | `multipass` | `chameleon` | `aws` |
| **VM size** | 1 vCPU, 2 GB (set in `~/.config/cloudmesh/clouds.yaml`) | `m1.small` (1 vCPU, 2 GB) | `t3.small` (2 vCPU, 2 GB) |
| **OS image** | Ubuntu 22.04 | CC-Ubuntu22.04 | Ubuntu 22.04 |
| **How the service is reached** | The VM's local IP | Floating IP | The instance's public IP |
| **Port 8000** | Open by default | Rule added with `cmx vm security-group` | Rule in the instance's security group |
| **Special step** | None | `cmx vm start` creates a lease; end the lease after `cmx vm delete` | Delete the instance after every session |
| **Status** | `cmx vm` VM lifecycle tested | `start`, `list`, `ip assign`, `delete` tested (Oct 14) | Account and credentials not set up yet |

**The steps `deploy.sh` runs on every cloud:**

```bash
cmx vm cloud set chameleon                 # multipass | chameleon | aws
cmx vm start inferscale                    # Chameleon: also creates a lease (--duration 2h)
cmx vm list                                # shows the VM and its IP
cmx vm run inferscale "curl -fsSL https://get.docker.com | sudo sh && sudo docker run -d -p 8000:8000 ghcr.io/shabbir04/inferscale:latest"
curl http://<ip>:8000/health               # smoke test
locust -f loadtest.py --headless -u 10 -r 2 -t 60s --host http://<ip>:8000
cmx vm delete inferscale                   # Chameleon: then delete the lease
```

On Chameleon a VM can also be started without an IP (`cmx vm start inferscale --ip no`) and get one
later with `cmx vm ip assign inferscale`, the command I added in
[#66](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/66).

**Multi-cloud failover.** `deploy.sh` writes each cloud's IP into a small config file. `client.py` tries
the clouds in order, so the service keeps answering when one cloud is down:

```python
import requests

CLOUDS = ["http://<aws-ip>:8000", "http://<chameleon-ip>:8000", "http://<multipass-ip>:8000"]

def predict(text):
    for url in CLOUDS:
        try:
            return requests.post(f"{url}/predict", json={"text": text}, timeout=3).json()
        except requests.RequestException:
            continue  # this cloud is down, try the next one
    raise RuntimeError("all clouds are down")
```

The demo: run requests through `client.py`, delete the AWS VM with `cmx vm delete`, and the requests
keep working through Chameleon.

### 5.3 DevOps Pipeline

| Stage | Tool | What it does |
| ----- | ---- | ------------ |
| Source | GitHub | One branch per change, pull requests, issues |
| Test | pytest (GitHub Actions) | Tests `/health` and `/predict` on every push |
| Build | Docker (GitHub Actions) | Builds the image and pushes it to GitHub Container Registry |
| Deploy | `deploy.sh` + `cmx vm` | Creates the VM and starts the container on the chosen cloud |
| Verify | `curl /health`, Locust | Checks the service, then measures latency |
| Monitor | `/stats` + `monitor.py` | Shows live requests, errors and average response time for all three clouds |
| Clean up | `cmx vm delete` | Removes the VM (and the Chameleon lease) after each session |

The Python environment is a `venv` with `pip`, not conda, which keeps the VMs and containers clean.

### 5.4 AI / Model Serving

The model is `distilbert/distilbert-base-uncased-finetuned-sst-2-english`. It is small enough to run on a
CPU and fit in a 2 GB VM. The core of the service:

```python
from fastapi import FastAPI
from transformers import pipeline

app = FastAPI()
classifier = pipeline("sentiment-analysis",
                      model="distilbert/distilbert-base-uncased-finetuned-sst-2-english")

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/predict")
def predict(item: dict):
    return classifier(item["text"])[0]   # e.g. {"label": "POSITIVE", "score": 0.99}

@app.post("/filter")
def filter_reviews(item: dict):
    # e.g. {"texts": [...], "label": "NEGATIVE", "min_score": 0.9} -> only the confident negative reviews
    label = item.get("label", "NEGATIVE")
    min_score = item.get("min_score", 0.9)
    results = classifier(item["texts"])
    return [{"text": t, **r} for t, r in zip(item["texts"], results)
            if r["label"] == label and r["score"] >= min_score]
```

`/stats` returns the number of requests, the number of errors and the average response time. A small
FastAPI middleware counts them for every request, and `monitor.py` reads them.

### 5.5 Security

- Login to VMs only with SSH keys, no passwords.
- Cloud credentials stay in `~/.config/` and are never committed to Git.
- Port 8000 is opened only for testing, and every VM is deleted after each session.
- The test data is public example text, with no personal data.

---

## 6. Project Plan & Timeline

| Phase | Tasks | When | Status |
| ----- | ----- | ---- | ------ |
| Topic | Title, first summary | Sep 23 – Oct 1 | Done |
| `cmx vm` on two clouds | VM lifecycle on Multipass and Chameleon; fixes merged ([#39](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/39), [#41](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/41)); `cmx vm ip` command ([#66](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/66)) | Sep 29 – Oct 14 | Done |
| Simpler design | Three clouds + `cmx vm` instead of Kubernetes | Oct 14 | Done |
| Third cloud | AWS account and credentials, first `cmx vm` VM on AWS | Oct 15 – Oct 22 | Next |
| Service | FastAPI + model, review filter (`/filter`), `/stats`, Dockerfile, tests | Oct 15 – Oct 29 | Next |
| CI | GitHub Actions: test, build, push image | Oct 29 – Nov 5 | Planned |
| Deploy script | `deploy.sh` for all three clouds | Nov 5 – Nov 12 | Planned |
| Monitoring + failover | `monitor.py`, `client.py` | Nov 12 – Nov 19 | Planned |
| Measurements | Load tests and the failover test on the three clouds, results table | Nov 19 – Dec 3 | Planned |
| Final | Report and presentation | Dec 3 – Dec 10 | Planned |

---

## 7. Resources & Budget

| Resource | Use | Cost |
| -------- | --- | ---- |
| Multipass on my Mac | Development and the local cloud | $0 |
| Chameleon KVM@TACC, `m1.small` | 1–2 hour leases per session (project CH-817419) | Class allocation, no money |
| AWS EC2 `t3.small` | Short sessions, deleted afterwards | About $0.02 per hour, covered by AWS Free plan credits |
| GitHub Actions and Container Registry | CI and image storage | $0 within the free limits |
| **Total** | | **$0 out of pocket** |

---

## 8. Risk Management

| Risk | Likelihood | Impact | Mitigation |
| ---- | ---------- | ------ | ---------- |
| Chameleon has no free capacity ("No valid host was found") | Medium | Delay | Retry at another time; keep sessions short |
| A Chameleon lease keeps running after `cmx vm delete` | High | Uses allocation | End the lease after every session |
| An AWS instance is left running | Low | Cost | Delete after every session; set a billing alert |
| The model needs more memory than the VM has | Medium | Service crashes | Use 2 GB VMs; add swap or use a smaller model |
| Credentials leak | Low | High | Keep them only in `~/.config/`, never in Git |
| The failover demo needs two or three clouds running at once | Medium | More cost and allocation | Keep the demo under 30 minutes and delete everything right after |

---

## 9. Evaluation & Success Metrics

| Metric | How it is measured | Target |
| ------ | ------------------ | ------ |
| Deploy time (`cmx vm start` → first good `/predict`) | Timer in `deploy.sh` | Under 15 minutes on each cloud |
| Latency p50 / p95 | Locust, 60 s, 10 users | Reported per cloud |
| Success rate | Locust | At least 99 % |
| Cost per session | Provider pricing and allocation used | Under $1 per AWS session |
| Same script on all three clouds | Run `deploy.sh` with each cloud | Works without changes to the steps |
| Review filter accuracy | `/filter` on 20 reviews I label by hand | At least 18 of 20 correct |
| Live monitoring | `monitor.py` during a load test | All three clouds shown, updated every 5 seconds |
| Failover | 200 requests through `client.py`, AWS VM deleted halfway | At least 99 % succeed |

---

## 10. Deliverables

| Deliverable | Format |
| ----------- | ------ |
| Inference service, Dockerfile and tests | Code in this repository |
| GitHub Actions workflow | `.github/workflows/` |
| `deploy.sh` built on `cmx vm` | Script in this repository |
| Review filter (`/filter`) and `/stats` | Part of the inference service |
| `monitor.py` (live monitoring) | Script in this repository |
| `client.py` (multi-cloud failover) | Script in this repository |
| Results table and chart for the three clouds | Markdown in this repository |
| Contributions to `cmx vm` | Pull requests to cloudmesh-ai-vm |
| Presentation | In class |

---

## 11. Issues

- **AWS is not set up yet.** I still need the account and credentials, and I have not tested whether the
  `aws` provider in `cmx vm` supports everything the deploy script needs (public IP, security group rule).
  If not, I open the port in the AWS console and report the gap.
- **Which Chameleon code to use.** `cmx vm` has two versions for Chameleon: the `dev2` branch and the
  `feature/chameleon-native-chi` branch. I need to know which one the project should build on.
- **Chameleon clean-up gaps.** `cmx vm delete` does not end the lease, and releasing a floating IP fails
  because python-chi uses a compute call that KVM@TACC no longer supports, so IPs stay reserved
  (reported in [#48](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/issues/48) and
  [#66](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/66)).
- **`cmx vm --cloud` is ignored on `dev2`**, so the deploy script switches clouds with `cmx vm cloud set`.
- **Is 2 GB enough** for DistilBERT plus Docker? If not, I add swap or use a smaller model.
- **The VMs are not identical** (`t3.small` has 2 vCPUs, `m1.small` has 1), so the results note the
  differences instead of treating them as a perfectly fair comparison.
- **Failover is done in the client.** It is the simplest way. A load balancer in front of the clouds would
  be more realistic, but it needs another VM. The cloud IPs also change with every deployment, so
  `deploy.sh` has to update the client's config file each time.

---

## 12. References

- cloudmesh-ai-vm (`cmx vm`): https://github.com/cloudmesh-ai/cloudmesh-ai-vm
- Multipass: https://canonical.com/multipass
- Chameleon Cloud documentation: https://chameleoncloud.readthedocs.io
- Amazon EC2 documentation: https://docs.aws.amazon.com/ec2/
- AWS Free Tier: https://aws.amazon.com/free/
- FastAPI: https://fastapi.tiangolo.com
- DistilBERT SST-2 model: https://huggingface.co/distilbert/distilbert-base-uncased-finetuned-sst-2-english
- Locust: https://locust.io
