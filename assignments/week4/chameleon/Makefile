# Chameleon Cloud (KVM@TACC) VM management with the OpenStack CLI.
# KVM@TACC requires a Blazar lease: reserve a flavor first, then boot
# the VM on the reserved flavor "reservation:<reservation-id>".

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
LEASE_NAME  ?= $(VM_NAME)-lease
LEASE_HOURS ?= 4
AMOUNT      ?= 1
NODES       ?= $(USER)-node1 $(USER)-node2
CLUSTER_LEASE ?= $(USER)-cluster-lease

OS := openstack --os-cloud $(OS_CLOUD)

# Reservation id of the flavor reservation inside $(LEASE_NAME)
RES_ID = $$($(OS) reservation lease show $(LEASE_NAME) -f json | python3 -c \
	'import json,sys; r=json.load(sys.stdin)["reservations"]; r=json.loads(r) if isinstance(r,str) else r; print((r[0] if isinstance(r,list) else r)["id"])')
FIP = $$($(OS) floating ip list --tags $(VM_NAME) -f value -c "Floating IP Address" | head -1)

.PHONY: help install check keypair secgroup setup lease lease-status lease-extend lease-delete \
	create fip status list ip ssh start stop reboot delete release clean \
	cluster-lease cluster-create cluster-status cluster-stop cluster-clean \
	chi-up chi-down

help:
	@echo "Usage: make <target> [VM_NAME=<name>] [OS_CLOUD=chameleon]"
	@echo "Setup:"
	@echo "  install        - Install openstack CLI (+Blazar plugin) and python-chi"
	@echo "  check          - Verify credentials (issue a token)"
	@echo "  keypair        - Upload $(PUBKEY) as keypair $(KEY_NAME)"
	@echo "  secgroup       - Create security group $(SECGROUP) allowing SSH"
	@echo "  setup          - check + keypair + secgroup"
	@echo "Lease (reservation):"
	@echo "  lease          - Reserve $(AMOUNT) x $(FLAVOR) for $(LEASE_HOURS)h"
	@echo "  lease-status   - Show the lease"
	@echo "  lease-extend   - Extend the lease by LEASE_HOURS"
	@echo "  lease-delete   - Delete the lease (frees the reservation)"
	@echo "Single VM:"
	@echo "  create         - Boot VM on the reserved flavor, wait, attach floating IP"
	@echo "  status         - Show VM details"
	@echo "  list           - List all servers"
	@echo "  ip             - Print the VM floating IP"
	@echo "  ssh            - SSH into the VM"
	@echo "  start/stop/reboot"
	@echo "  delete         - Delete VM and release its floating IP"
	@echo "  clean          - delete + lease-delete"
	@echo "Multiple VMs (NODES=\"$(NODES)\"):"
	@echo "  cluster-lease  - One lease for $(words $(NODES)) instances"
	@echo "  cluster-create - Create every node on that lease"
	@echo "  cluster-status - List servers and the cluster lease"
	@echo "  cluster-stop   - Stop all nodes"
	@echo "  cluster-clean  - Delete all nodes and the cluster lease"
	@echo "python-chi alternative:"
	@echo "  chi-up / chi-down - Same lifecycle via chi_vm.py (python-chi)"

# ---------- setup ----------
install:
	pipx install python-openstackclient || true
	pipx inject python-openstackclient python-blazarclient
	pip install python-chi

check:
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

# ---------- lease ----------
lease:
	$(OS) reservation lease create \
		--reservation resource_type=flavor:instance,flavor_id=$$($(OS) flavor show $(FLAVOR) -f value -c id),amount=$(AMOUNT) \
		--end-date "$$(python3 -c 'import datetime as d; print((d.datetime.now(d.timezone.utc)+d.timedelta(hours=$(LEASE_HOURS))).strftime("%Y-%m-%d %H:%M"))')" \
		$(LEASE_NAME)
	@echo "Waiting for lease to become ACTIVE..."
	@until [ "$$($(OS) reservation lease show $(LEASE_NAME) -f value -c status)" = "ACTIVE" ]; do sleep 5; done
	@echo "Lease $(LEASE_NAME) ACTIVE, reservation $(RES_ID)"

lease-status:
	$(OS) reservation lease show $(LEASE_NAME)

lease-extend:
	$(OS) reservation lease set --prolong-for "$(LEASE_HOURS)h" $(LEASE_NAME)

lease-delete:
	-$(OS) reservation lease delete $(LEASE_NAME)

# ---------- single VM ----------
create:
	$(OS) server create \
		--flavor "reservation:$(RES_ID)" \
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

clean: delete lease-delete

# ---------- multiple VMs ----------
cluster-lease:
	$(MAKE) lease LEASE_NAME=$(CLUSTER_LEASE) AMOUNT=$(words $(NODES))

cluster-create:
	@for node in $(NODES); do \
		$(MAKE) --no-print-directory create VM_NAME=$$node LEASE_NAME=$(CLUSTER_LEASE) || true; \
	done

cluster-status:
	$(OS) server list
	$(OS) reservation lease show $(CLUSTER_LEASE) -c name -c status -c end_date

cluster-stop:
	@for node in $(NODES); do \
		$(OS) server stop $$node || true; \
	done

cluster-clean:
	@for node in $(NODES); do \
		$(MAKE) --no-print-directory delete VM_NAME=$$node || true; \
	done
	$(MAKE) lease-delete LEASE_NAME=$(CLUSTER_LEASE)

# ---------- python-chi ----------
chi-up:
	python3 chi_vm.py --cloud $(OS_CLOUD) up --lease $(LEASE_NAME) --hours $(LEASE_HOURS) \
		--flavor $(FLAVOR) --image $(IMAGE) --key $(KEY_NAME) $(VM_NAME)

chi-down:
	python3 chi_vm.py --cloud $(OS_CLOUD) down --lease $(LEASE_NAME) $(VM_NAME)
