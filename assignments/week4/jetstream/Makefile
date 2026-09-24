OS_CLOUD ?= jetstream2
VM_NAME  ?= js2-vm
IMAGE    ?= "Featured-Ubuntu22"
FLAVOR   ?= m3.tiny
NET_NAME ?= auto_allocated_network
NODES    ?= js2-node1 js2-node2

.PHONY: help status create start stop ip delete clean cluster-create cluster-status cluster-stop cluster-clean

help:
	@echo "Targets:"
	@echo "  create         - Launch a single Jetstream 2 VM"
	@echo "  status         - Show details of the VM"
	@echo "  start          - Power on the VM"
	@echo "  stop           - Power off the VM"
	@echo "  ip             - Print VM IP address"
	@echo "  delete/clean   - Delete the VM"
	@echo "  cluster-create - Launch multiple instances"
	@echo "  cluster-status - List all instances"
	@echo "  cluster-stop   - Stop all instances"
	@echo "  cluster-clean  - Delete all instances"

create:
	openstack --os-cloud $(OS_CLOUD) server create \
		--flavor $(FLAVOR) \
		--image $(IMAGE) \
		--network $(NET_NAME) \
		$(VM_NAME)

status:
	openstack --os-cloud $(OS_CLOUD) server show $(VM_NAME)

start:
	openstack --os-cloud $(OS_CLOUD) server start $(VM_NAME)

stop:
	openstack --os-cloud $(OS_CLOUD) server stop $(VM_NAME)

ip:
	@openstack --os-cloud $(OS_CLOUD) server show $(VM_NAME) -c addresses -f value

delete:
	openstack --os-cloud $(OS_CLOUD) server delete $(VM_NAME)

clean: delete

cluster-create:
	@for node in $(NODES); do \
		openstack --os-cloud $(OS_CLOUD) server create \
			--flavor $(FLAVOR) \
			--image $(IMAGE) \
			--network $(NET_NAME) \
			$$node || true; \
	done

cluster-status:
	openstack --os-cloud $(OS_CLOUD) server list

cluster-stop:
	@for node in $(NODES); do \
		openstack --os-cloud $(OS_CLOUD) server stop $$node || true; \
	done

cluster-clean:
	@for node in $(NODES); do \
		openstack --os-cloud $(OS_CLOUD) server delete $$node || true; \
	done
