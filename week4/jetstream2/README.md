# Assignment W4.2: VM on Jetstream 2 via Makefile

## 1. Setup & CLI
* OpenStack CLI installed via `pipx`.
* Authenticated using application credentials under `clouds.yaml` (`--os-cloud jetstream2`).

## 2. Managing Multiple Machines
* **Dynamic Variable Overrides:** Targeting specific instances on demand with variable arguments (e.g., `make create VM_NAME=worker-01`).
* **Batch Targets:** Looping across a list variable (`NODES ?= js2-node1 js2-node2`) inside cluster targets (`cluster-create`, `cluster-status`, `cluster-clean`).
