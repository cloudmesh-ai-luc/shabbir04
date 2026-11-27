# Status

## Keeping up with Piazza (@194)

* The class statistics showed **99 viewed posts**, below 140. Most posts had still been read: every new post arrives as an email notification in Outlook with the full text, but Piazza only counts posts that are opened on the website.
* On Nov 19 the remaining posts were opened on the web interface: **173 viewed**, 7 unread.
* From now on, as @191 asks: read Piazza on the web interface every day before working on `cmx` or the project, and receive notifications for follow-ups and replies too, not only new posts.

## Week of Nov 19, 2026

* **Proficiency check ([@218](https://piazza.com/class/mt5rkdsycb31c3/post/218), private):** screen recording of Cline with the Jetstream LLM (`gemma-4-31b-it`) on `cloudmesh-ai-vm` `dev3`, including checking its answer against the code, and a terminal recording: `ls ~/work`, SSH-key access to GitHub, fork `Shabbir04/cloudmesh-ai-vm` (origin) with `cloudmesh-ai/cloudmesh-ai-vm` (upstream), and an SSH clone. All repos in `~/work` now use SSH remotes. My own first check of Cline's answer was wrong (there are two identical copies of `ui.py`), so I posted a correction.
* **Jetstream:** smoke test on `dev3` @ `2765574` with Python 3.15.2: 1 failed, 1 passed. Fixes: [PR #141](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/141) ([#140](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/issues/140), full VM names in `cmx vm list`, the failure from Nov 5) and [PR #143](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/143) ([#142](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/issues/142), floating IP shown in `cmx vm list`). Evidence for the `key_path` SSH problem from Nov 5 added to [#131](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/issues/131#issuecomment-7003525688).
* **Multipass:** smoke test passed (45 s). [PR #145](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/145) ([#144](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/issues/144)): `cmx vm start <name>` resumes a stopped Multipass VM again (the behavior from my issue #49).
* **Chameleon:** smoke test skipped. The server went to ERROR (`No valid host was found`), `cmx` did not detect it and left the ERROR VM and an active lease behind (removed by hand). Reproduction and a pseudo algorithm posted on [#125](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/issues/125#issuecomment-7004189242). Released the floating IP left over from the Nov 5 test.
* **Install on `dev3`:** `make install` fails because ChameleonCloud renamed `ccauth` to `chameleon-ccauth` (#128). Fixed locally by renaming the dependency; not committed, waiting for the upstream fix.

## Week of Nov 5, 2026

* **Jetstream LLM in Cline:** Cline 4.1.26 in VS Code is connected to the Jetstream LLM (`gemma-4-31b-it`, OpenAI-compatible API at `https://llm.jetstream-cloud.org/api`). Key and chat tested on Nov 5 ([screenshot](images/cline-jetstream-2026-11-05.png): Cline runs a command and asks before reading a file).
* **Multi-cloud smoke tests** on `cloudmesh-ai-vm` `dev3` (9732e92) with Python 3.15.2, `make multipass|chameleon|jetstream`:
  * Multipass: **passed** (33 s).
  * Chameleon KVM@TACC: start, list, stop, delete, images and flavors work; the key-upload step is skipped (`key_path` means the public key in cmx but the private key in the test) and the floating IP is not released (CHI 404). Issues with action plans to be filed after class.
  * Jetstream: the VM starts, gets a floating IP and SSH works; the lifecycle test fails because `cmx vm list` shortens long VM names in its table. Issue to be filed after class.
* **Python 3.12+ (@181):** the project now requires `>=3.12` (6 tests pass on 3.13), the W4.4 venv was rebuilt with 3.13, and the class code runs on 3.15.2 as `dev3` requires.
* **Time and availability (@174):** reply to follow after class.
* **Public cloud (W7.1):** AWS is not set up yet.

## Week of Oct 29, 2026

* Project layout like `cloudmesh-ai-llm-mock`: [`src/inferscale/`](../src/inferscale), [`Makefile`](../Makefile), [`pyproject.toml`](../pyproject.toml), MkDocs in [`docs/`](../docs). 6 unit tests pass (`make test`).
* Used the Jetstream LLM to review the project ([llm-review.md](llm-review/llm-review.md), script [`llm_review.py`](llm-review/llm_review.py)): applied 3 of its 10 suggestions, rejected or postponed 7 with reasons.
* Added the [12-slide presentation](../docs/project/InferScale-Presentation.pdf) and extended [project.md](../docs/project/project.md) (PostgreSQL data tier, requirements, API, login security, testing plan).

## Week of Oct 15, 2026 (Week 7)

* Rewrote [project.md](../docs/project/project.md) for one inference service on three clouds with `cmx vm` (architecture diagram, Prometheus and Grafana monitoring, frontend tier).
* Opened [cloudmesh-ai-vm#66](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/66): `cmx vm ip assign` / `ip release`, tested on Chameleon; merged into `dev2` on Oct 19.
* Wrote the [W7.2 summary of my cmx contributions](../README.md#w72-summary-my-contributions-to-cmx-cloudmesh-ai-vm).
* My issues [#49](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/issues/49) and [#50](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/issues/50) were fixed (Oct 12); [#48](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/issues/48) was closed on Oct 24.
