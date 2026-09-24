# Assignment W4.3: VM on Chameleon Cloud via Makefile

## 1. OpenStack command-line client
* `python-openstackclient` installed with `pipx`.
* The Blazar plugin is added with `pipx inject python-openstackclient python-blazarclient`. It provides `openstack reservation ...`, which you need because KVM@TACC only boots VMs on a **reserved flavor**.
* Credentials: an application credential from the KVM@TACC dashboard (*Identity → Application Credentials*), stored in `~/.config/openstack/clouds.yaml`:

```yaml
clouds:
  chameleon:
    auth_type: v3applicationcredential
    auth:
      auth_url: https://kvm.tacc.chameleoncloud.org:5000/v3
      application_credential_id: "<id>"
      application_credential_secret: "<secret>"
    region_name: KVM@TACC
    interface: public
    identity_api_version: 3
```

## 2. python-chi
* `pip install python-chi` (v1.2.10).
* `chi_vm.py` does the same lifecycle with python-chi (`Lease` → `add_flavor_reservation` → `Server.submit` → `associate_floating_ip`). It reads credentials from the same `clouds.yaml` entry.

## 3. Targets needed for a single VM
| Phase | Target | Why |
|---|---|---|
| Setup | `install`, `check`, `keypair`, `secgroup` (`setup` runs the last three) | Install the tools, confirm auth, upload an SSH key, open port 22 |
| Reserve | `lease`, `lease-status`, `lease-extend`, `lease-delete` | Chameleon needs a Blazar lease before a VM can boot |
| Lifecycle | `create`, `start`, `stop`, `reboot`, `delete` | Boot on `reservation:<id>` flavor, change power state, delete |
| Access | `fip`, `ip`, `ssh`, `status`, `list` | Public IP (tagged with the VM name), log in as `cc` |
| Cleanup | `release`, `clean` | Free floating IPs and the lease so they don't count against your allocation |

Typical run:
```bash
make setup
make lease
make create
make ssh
make clean
```

## 4. Managing multiple machines
* **Variable overrides:** `make lease create VM_NAME=worker1` sets up a separate VM with its own lease (`worker1-lease`).
* **Cluster targets:** `cluster-lease` makes **one** lease with `amount = $(words $(NODES))`. `cluster-create` then runs `create` for each node on that lease. `cluster-clean` deletes the nodes and their IPs, then the lease.
  ```bash
  make cluster-lease cluster-create NODES="n1 n2 n3"
  make cluster-clean NODES="n1 n2 n3"
  ```
* **python-chi:** `python3 chi_vm.py up --lease L --key K n1 n2 n3` reserves 3 instances and boots all of them.

## 5. Test run (2026-09-24, KVM@TACC)
| Step | Result |
|---|---|
| `make check` | Token issued with the application credential |
| `make setup` | Keypair `khajashabbirahmed-key` uploaded, `allow-ssh` group (tcp/22) created |
| `make lease` | **Failed**: Blazar API returns `500 Internal Server Error` for every lease request made with an application credential (also through python-chi and for floating-IP leases) |
| Workaround | Lease `khajashabbirahmed-vm-lease` (1 × m1.small) created in the dashboard: *Reservations → Leases → Create Lease* |
| `make create` | VM `khajashabbirahmed-vm` ACTIVE on flavor `reservation:<id>`, floating IP attached |
| `make ssh` | Logged in as `cc` (Ubuntu 22.04, kernel 5.15) |
| `make stop` / `make start` | SHUTOFF → ACTIVE, floating IP kept |

A lease made in the dashboard works with every target because `create` only looks the lease up by name (`LEASE_NAME`). Names default to `$(USER)-…`, so they don't clash with classmates in the shared project.
