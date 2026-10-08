# Chameleon Cloud (KVM@TACC) VM management with the OpenStack CLI.
# KVM@TACC runs regular OpenStack VMs: no reservation (lease) is needed.

# Parameters
OS_CLOUD    ?= chameleon
VM_NAME     ?= $(USER)-vm
IMAGE       ?= CC-Ubuntu22.04
FLAVOR      ?= m1.small
NETWORK     ?= sharednet1
EXT_NET     ?= public
KEY_NAME    ?= $(USER)-key
PUBKEY      ?= $(HOME)/.ssh/id_ed25519.pub
SECGROUP    ?= allow-ssh
SSH_USER    ?= cc
NODES       ?= $(USER)-node1 $(USER)-node2

OS := openstack --os-cloud $(OS_CLOUD)

FIP = $$($(OS) floating ip list --tags $(VM_NAME) -f value -c "Floating IP Address" | head -1)

.PHONY: help install check keypair secgroup setup \
	create fip status list ip ssh start stop reboot delete release clean \
	cluster-create cluster-status cluster-stop cluster-clean

help:
	@echo "Usage: make <target> [VM_NAME=<name>] [OS_CLOUD=chameleon]"
	@echo "Setup:"
	@echo "  install        - Install openstack CLI and python-chi"
	@echo "  check          - Show the Chameleon site (KVM@TACC) and verify credentials"
	@echo "  keypair        - Upload $(PUBKEY) as keypair $(KEY_NAME)"
	@echo "  secgroup       - Create security group $(SECGROUP) allowing SSH"
	@echo "  setup          - check + keypair + secgroup"
	@echo "Single VM:"
	@echo "  create         - Boot a $(FLAVOR) VM, wait, attach floating IP"
	@echo "  status         - Show VM details"
	@echo "  list           - List all servers"
	@echo "  ip             - Print the VM floating IP"
	@echo "  ssh            - SSH into the VM"
	@echo "  start/stop/reboot"
	@echo "  delete/clean   - Delete VM and release its floating IP"
	@echo "Multiple VMs (NODES=\"$(NODES)\"):"
	@echo "  cluster-create - Create every node"
	@echo "  cluster-status - List servers"
	@echo "  cluster-stop   - Stop all nodes"
	@echo "  cluster-clean  - Delete all nodes and their floating IPs"

# ---------- setup ----------
install:
	pipx install python-openstackclient || true
	pip install python-chi

check:
	@echo "Site:     $$($(OS) configuration show -f value -c region_name)"
	@echo "Endpoint: $$($(OS) configuration show -f value -c auth.auth_url)"
	$(OS) token issue -c expires -c project_id

keypair:
	@$(OS) keypair show $(KEY_NAME) >/dev/null 2>&1 \
		&& echo "keypair $(KEY_NAME) exists" \
		|| $(OS) keypair create --public-key $(PUBKEY) $(KEY_NAME)

secgroup:
	@$(OS) security group show $(SECGROUP) >/dev/null 2>&1 \
		&& echo "security group $(SECGROUP) exists" \
		|| ( $(OS) security group create $(SECGROUP) --description "SSH in" \
		  && $(OS) security group rule create $(SECGROUP) --protocol tcp --dst-port 22 --remote-ip 0.0.0.0/0 )

setup: check keypair secgroup

# ---------- single VM ----------
create:
	$(OS) server create \
		--flavor $(FLAVOR) \
		--image $(IMAGE) \
		--network $(NETWORK) \
		--key-name $(KEY_NAME) \
		--security-group default \
		--security-group $(SECGROUP) \
		--wait \
		$(VM_NAME)
	@$(MAKE) --no-print-directory fip

fip:
	@ip=$$($(OS) floating ip create $(EXT_NET) --tag $(VM_NAME) -f value -c floating_ip_address) \
		&& $(OS) server add floating ip $(VM_NAME) $$ip \
		&& echo "$(VM_NAME) -> $$ip"

status:
	$(OS) server show $(VM_NAME) -c name -c status -c addresses -c image

list:
	$(OS) server list

ip:
	@echo $(FIP)

ssh:
	ssh -o StrictHostKeyChecking=accept-new $(SSH_USER)@$(FIP)

start:
	$(OS) server start $(VM_NAME)

stop:
	$(OS) server stop $(VM_NAME)

reboot:
	$(OS) server reboot $(VM_NAME)

release:
	@for ip in $$($(OS) floating ip list --tags $(VM_NAME) -f value -c ID); do \
		$(OS) floating ip delete $$ip; done

delete: release
	-$(OS) server delete --wait $(VM_NAME)

clean: delete

# ---------- multiple VMs ----------
cluster-create:
	@for node in $(NODES); do \
		$(MAKE) --no-print-directory create VM_NAME=$$node || true; \
	done

cluster-status:
	$(OS) server list

cluster-stop:
	@for node in $(NODES); do \
		$(OS) server stop $$node || true; \
	done

cluster-clean:
	@for node in $(NODES); do \
		$(MAKE) --no-print-directory delete VM_NAME=$$node || true; \
	done
