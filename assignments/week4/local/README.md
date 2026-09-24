# Assignment W4.1: VM on Local Machine via Makefile

## 1. Local VM Framework
* Framework: Multipass (v1.16.3)
* Operating System: Ubuntu 24.04 LTS
* Rationale: Lightweight CLI orchestration without GUI or conda overhead.

## 2. Managing Multiple Machines
* Runtime Overrides: Parameterize target instances (e.g., make create VM_NAME=worker1).
* Batch Targets: Loop over node lists (NODES ?= node1 node2) via cluster-create and cluster-clean.

## 3. Makefile Organization Across Environments
* Directory Separation: Dedicated directories (local/, jetstream/, chameleon/) keep credentials and configs isolated.
* Top-Level Orchestration: Root Makefile delegates commands using $(MAKE) -C <dir> <target>.
