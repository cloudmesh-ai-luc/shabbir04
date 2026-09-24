# Parameters
VM_NAME ?= local-vm
IMAGE   ?= 24.04
CPUS    ?= 2
MEMORY  ?= 2G
DISK    ?= 10G
NODES   ?= node1 node2

.PHONY: help create start stop status shell ip delete purge clean cluster-create cluster-status cluster-stop cluster-clean

help:
	@echo "Usage: make <target> [VM_NAME=<name>]"
	@echo "Single VM Targets:"
	@echo "  create         - Launch a new VM"
	@echo "  start          - Start the VM"
	@echo "  stop           - Stop the VM"
	@echo "  status         - Check VM status"
	@echo "  shell          - Open a terminal shell in the VM"
	@echo "  ip             - Show primary IPv4 address"
	@echo "  delete         - Delete the VM"
	@echo "  purge          - Purge deleted instances"
	@echo "  clean          - Delete and purge VM"
	@echo "Multi-VM Targets:"
	@echo "  cluster-create - Launch predefined cluster nodes"
	@echo "  cluster-status - List all running multipass VMs"
	@echo "  cluster-stop   - Stop all cluster nodes"
	@echo "  cluster-clean  - Delete and purge cluster nodes"

create:
	multipass launch $(IMAGE) --name $(VM_NAME) --cpus $(CPUS) --memory $(MEMORY) --disk $(DISK)

start:
	multipass start $(VM_NAME)

stop:
	multipass stop $(VM_NAME)

status:
	multipass info $(VM_NAME)

shell:
	multipass shell $(VM_NAME)

ip:
	@multipass info $(VM_NAME) | awk '/IPv4/ {print $$2}'

delete:
	multipass delete $(VM_NAME)

purge:
	multipass purge

clean: delete purge

cluster-create:
	@for node in $(NODES); do \
		multipass launch $(IMAGE) --name $$node --cpus 1 --memory 1G || true; \
	done

cluster-status:
	multipass list

cluster-stop:
	@for node in $(NODES); do \
		multipass stop $$node || true; \
	done

cluster-clean:
	@for node in $(NODES); do \
		multipass delete $$node || true; \
	done
	multipass purge
