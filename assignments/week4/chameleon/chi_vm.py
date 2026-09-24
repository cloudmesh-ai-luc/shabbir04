#!/usr/bin/env python3
"""Manage Chameleon KVM@TACC VMs with python-chi.

Credentials come from the same clouds.yaml entry the Makefile uses
(--cloud chameleon), so there is only one place to keep them.

    python3 chi_vm.py up   --lease my-lease vm1 [vm2 ...]
    python3 chi_vm.py down --lease my-lease vm1 [vm2 ...]
    python3 chi_vm.py status vm1 [vm2 ...]
"""
import argparse
import os
from datetime import timedelta

import openstack.config


def load_credentials(cloud):
    """Export a clouds.yaml entry as the OS_* variables python-chi reads."""
    cfg = openstack.config.OpenStackConfig().get_one(cloud).config
    auth = cfg["auth"]
    os.environ["OS_AUTH_URL"] = auth["auth_url"]
    os.environ["OS_REGION_NAME"] = cfg.get("region_name") or "KVM@TACC"
    if "application_credential_id" in auth:
        os.environ["OS_AUTH_TYPE"] = "v3applicationcredential"
        os.environ["OS_APPLICATION_CREDENTIAL_ID"] = auth["application_credential_id"]
        os.environ["OS_APPLICATION_CREDENTIAL_SECRET"] = auth["application_credential_secret"]
    else:
        os.environ["OS_AUTH_TYPE"] = "v3password"
        for key in ("username", "password", "project_id", "project_name",
                    "user_domain_name", "project_domain_name"):
            if auth.get(key):
                os.environ[f"OS_{key.upper()}"] = auth[key]


def up(args):
    from chi import lease, server

    lse = lease.Lease(args.lease, duration=timedelta(hours=args.hours))
    lse.add_flavor_reservation(name=args.flavor, amount=len(args.names))
    lse.submit(idempotent=True, wait_for_active=True)
    flavor = lse.get_reserved_flavors()[0]

    for name in args.names:
        vm = server.Server(name, image_name=args.image,
                           flavor_name=flavor.name, key_name=args.key)
        vm = vm.submit(idempotent=True, wait_for_active=True, show=None) or vm
        vm.refresh()
        if not vm.get_floating_ip():
            vm.associate_floating_ip()
        print(f"{name}: {vm.status} {vm.get_floating_ip()}")


def down(args):
    from chi import lease, server

    for name in args.names:
        try:
            server.get_server(name).delete(idempotent=True, delete_ips=True)
            print(f"{name}: deleted")
        except Exception as e:
            print(f"{name}: {e}")
    if args.lease:
        lease.delete_lease(args.lease)
        print(f"lease {args.lease}: deleted")


def status(args):
    from chi import server

    for name in args.names:
        vm = server.get_server(name)
        print(f"{name}: {vm.status} {vm.addresses}")


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--cloud", default="chameleon", help="clouds.yaml entry")
    sub = p.add_subparsers(dest="cmd", required=True)

    u = sub.add_parser("up", help="lease + create VMs + floating IPs")
    u.add_argument("--lease", required=True)
    u.add_argument("--hours", type=int, default=4)
    u.add_argument("--flavor", default="m1.small")
    u.add_argument("--image", default="CC-Ubuntu22.04")
    u.add_argument("--key", required=True, help="existing keypair name")
    u.add_argument("names", nargs="+")
    u.set_defaults(func=up)

    d = sub.add_parser("down", help="delete VMs, floating IPs and the lease")
    d.add_argument("--lease")
    d.add_argument("names", nargs="+")
    d.set_defaults(func=down)

    s = sub.add_parser("status")
    s.add_argument("names", nargs="+")
    s.set_defaults(func=status)

    args = p.parse_args()
    load_credentials(args.cloud)
    from chi import context
    context.use_site("KVM@TACC")
    args.func(args)


if __name__ == "__main__":
    main()
