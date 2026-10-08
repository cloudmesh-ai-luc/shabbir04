# Assignment W4.3: VM on Chameleon Cloud via Makefile

All of this assignment runs on **KVM@TACC**, Chameleon's virtual machine site (<https://kvm.tacc.chameleoncloud.org>, project `CH-817419`), not on the bare-metal sites like CHI@TACC. The `chameleon` entry in `clouds.yaml` points at KVM@TACC, VMs use the regular `m1.small` flavor with no reservation (lease), and `make check` prints the site before doing anything:

```
$ make check
Site:     KVM@TACC
Endpoint: https://kvm.tacc.chameleoncloud.org:5000/v3
```

## 1. OpenStack command-line client
* `python-openstackclient` installed with `pipx`.
* No reservation plugin is needed: KVM@TACC boots regular OpenStack flavors such as `m1.small` on demand.
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

## 3. Targets needed for a single VM
| Phase | Target | Why |
|---|---|---|
| Setup | `install`, `check`, `keypair`, `secgroup` (`setup` runs the last three) | Install the tools, confirm auth, upload an SSH key, open port 22 |
| Lifecycle | `create`, `start`, `stop`, `reboot`, `delete` | Boot an `m1.small` VM, change power state, delete |
| Access | `fip`, `ip`, `ssh`, `status`, `list` | Public IP (tagged with the VM name), log in as `cc` |
| Cleanup | `release`, `clean` | Delete the VM and free its floating IP so they don't count against the allocation |

Typical run:
```bash
make setup
make create
make ssh
make clean
```

## 4. Managing multiple machines
* **Variable overrides:** `make create VM_NAME=worker1` starts a separate VM; every target takes `VM_NAME=`.
* **Cluster targets:** `cluster-create`, `cluster-stop` and `cluster-clean` loop over `NODES`.
  ```bash
  make cluster-create NODES="n1 n2 n3"
  make cluster-clean NODES="n1 n2 n3"
  ```
* **Limit:** on-demand VMs only start if KVM@TACC has free capacity. On Oct 7 the first `m1.small` started, but a second one failed with `No valid host was found. There are not enough hosts available.` (my project has no instance quota, so this is the site's capacity). `m1.tiny` is too small for the Ubuntu image. So in practice I could run one VM at a time.

## 5. Test runs on KVM@TACC
**Oct 7, without a reservation** (current Makefile):

| Step | Result |
|---|---|
| `make check` | `Site: KVM@TACC`, token issued |
| `make setup` | Keypair `khajashabbirahmed-key` and `allow-ssh` group already exist |
| `make create` | `khajashabbirahmed-vm` ACTIVE on `m1.small`, floating IP attached |
| `make ssh` | Logged in as `cc` |
| `make stop` / `make start` | SHUTOFF → ACTIVE |
| `make cluster-create` | First node ACTIVE, second node `No valid host` (site capacity, see above) |
| `make clean` / `make cluster-clean` | All VMs and floating IPs removed |

**Sep 24** (first version, with a reservation): same results for create, ssh, stop/start and clean. That version reserved a flavor with a Blazar lease first. The professor pointed out that KVM@TACC doesn't need a reservation, so I removed the lease targets. (Creating leases through the API also failed with HTTP 500, so the Sep 24 lease was made in the dashboard.)
