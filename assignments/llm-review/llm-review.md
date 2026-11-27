# Jetstream LLM review of project.md

Model: `gemma-4-31b-it`, 2026-10-29

Here are 10 concrete suggestions to improve the InferScale project plan:

### Design
1. **Section 5.1 (Architecture):** Implement a **Health Check Endpoint for the Database** within the API. Currently, the API only checks the DB at startup. Adding a `/health/db` check allows Prometheus to alert specifically when the database container fails, distinguishing it from a model or network failure.
2. **Section 5.5 (AI/Model Serving):** Implement **Request Batching** in the `/filter` endpoint. Instead of iterating through the list of reviews, pass the entire list to the Hugging Face pipeline at once. This leverages PyTorch's internal optimizations and will significantly improve p95 latency during load tests.
3. **Section 11 (Issues):** Resolve the **VM CPU Disparity** by using a `t3.micro` (1 vCPU) on AWS instead of `t3.small` (2 vCPU). This ensures a "fair" comparison against the Chameleon `m1.small` and Multipass VMs, making the performance data scientifically valid.

### Security
4. **Section 5.6 (Security):** Move the **Database Password** from a file on the VM to an **Environment Variable** passed via `cmx vm run` or a secret manager. Storing it in `/etc/inferscale/db.env` leaves a plaintext secret on the disk; using environment variables reduces the forensic footprint.
5. **Section 5.6 (Security):** Implement **API Key Authentication** for `client.py` and Locust instead of Basic Auth. Basic Auth is designed for browsers; a dedicated `X-API-Key` header is more standard for programmatic access and easier to rotate without changing user accounts.

### Testing
6. **Section 5.9 (Testing):** Add **Negative Integration Tests** to the CI pipeline. Specifically, test that a request to `/api/predict` fails with a `401` when the `web` container is bypassed (if the port were accidentally opened) or when the wrong password is provided.
7. **Section 9 (Evaluation):** Include **Cold-Start Latency** as a metric. Measure the time from the first request hitting the VM to the first successful response. This will highlight the impact of the model loading time (20–60s) on the user experience.

### DevOps
8. **Section 5.2 (Deployment):** Replace the `curl | sh` Docker installation in `deploy.sh` with a **Custom Base Image** or a pre-baked VM image (if supported by `cmx vm`). Installing Docker at runtime increases deployment time and introduces a point of failure if the external script is unavailable.
9. **Section 5.3 (DevOps Pipeline):** Implement **Semantic Versioning** for Docker tags (e.g., `v1.0.1`) in addition to Git commits. This makes it easier to roll back to a known stable version across all three clouds if a new commit introduces a regression.

### AI
10. **Section 5.5 (AI/Model Serving):** Add a **Confidence Threshold Parameter** to the `/predict` endpoint. Instead of just returning the score, allow the user to specify a threshold; if the model is not confident enough, return a "Neutral/Uncertain" label. This improves the AI's reliability for end-users.

---

## My review of each suggestion

I checked every suggestion against `docs/project/project.md` and the code in `src/inferscale/`.

| # | Suggestion | Decision | Reason |
| - | ---------- | -------- | ------ |
| 1 | Database health check | Not now | `/health` does not check the database, but a database outage already gives `503` errors, which the `HighErrorRate` alert catches. |
| 2 | Batch the reviews in `/filter` | Rejected | Wrong premise: the code already passes the whole list to the model at once. The load test calls `/predict`, so it would not change the p95. |
| 3 | Use `t3.micro` (1 vCPU) on AWS | Rejected | Factually wrong: `t3.micro` has 2 vCPUs and only 1 GB of memory, which breaks the 2 GB target. (`t2.small`, 1 vCPU and 2 GB, would be the correct idea.) |
| 4 | Database password as an environment variable instead of a file | Rejected | It already reaches the container as an environment variable through `--env-file`. Passing it on the `cmx vm run` command line would show it in shell history and process lists. |
| 5 | API keys instead of Basic Auth | Rejected | Basic Auth over HTTPS works for scripts, and `client` and `prometheus` already have their own accounts that are easy to rotate. A second login method adds complexity. |
| 6 | Negative tests (wrong password, bypassing nginx) | Already planned | The container test in section 5.9 already checks that the login is required and that only port 443 is open. |
| 7 | Measure cold-start latency | **Applied** | Section 9 now reports the model start-up time per cloud: `docker run` to the first healthy `/api/health`. |
| 8 | Pre-built VM image instead of installing Docker | Not now | Needs custom images on three clouds and breaks "the same steps on every cloud". Possible future work. |
| 9 | Version tags on images | **Applied** | Images are tagged with the version from `VERSION` (for example `0.1.0`), the Git commit and `latest` (section 5.3). |
| 10 | `UNCERTAIN` below a confidence threshold | **Applied** | `/predict` takes an optional `min_score` and answers `UNCERTAIN` below it (sections 3.1, 5.5, 5.8), with a new unit test. |

Result: 3 applied, 7 not applied (2 factually wrong, 3 not needed, 2 for later).
