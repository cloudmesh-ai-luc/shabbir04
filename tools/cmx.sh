# Shared helpers for deploy.sh and monitor.sh: work on one VM ($VM) of one cloud ($OS_CLOUD) with cmx.
# Source this file; it does nothing on its own.

log() { printf '\n==> %s\n' "$*"; }
fail() { echo "ERROR: $*" >&2; exit 1; }

# Docker from Ubuntu's own packages (no script piped into sh), and the VM's user in the docker group
INSTALL_DOCKER="sudo apt-get -o DPkg::Lock::Timeout=600 update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=600 install -y -qq docker.io docker-compose-v2 make git
sudo usermod -aG docker \$(id -un)"

# Markers such as SSH''_OK are written with an empty '' inside: the VM's shell prints SSH_OK, but when a
# command fails, cmx repeats the command text (SSH''_OK) in its error message, which grep then cannot
# mistake for success.

# A short command on the VM (cmx vm run stops a command after 30 seconds)
run() { cmx vm run "$VM" "$1" 2>&1 | grep -v -i -E 'warning|^Authentication at site' || true; }

# A long command on the VM: it runs in the background there, and we check every 15 seconds until it ends
run_long() {
  local step=$1 code="" waited=0 script
  script=$(printf '%s\n' "set -e" "$2" | base64 | tr -d '\n')
  run "rm -f ~/.inferscale-$step.done; echo $script | base64 -d > ~/inferscale-$step.sh; \
nohup sh -c 'bash ~/inferscale-$step.sh > ~/inferscale-$step.log 2>&1; echo \$? > ~/.inferscale-$step.done' \
< /dev/null > /dev/null 2>&1 & echo START''ED" | grep -q STARTED || fail "could not start '$step' on $VM"
  while :; do
    code=$(run "echo DONE=\$(cat ~/.inferscale-$step.done 2>/dev/null)" | sed -n 's/.*DONE=\([0-9]*\).*/\1/p')
    [ -n "$code" ] && break
    [ "$waited" -lt "${3:-1800}" ] || fail "'$step' did not finish on $VM in time"
    sleep 15; waited=$((waited + 15)); printf '.'
  done
  echo
  if [ "$code" != 0 ]; then
    run "tail -20 ~/inferscale-$step.log"
    fail "'$step' failed on $VM (exit code $code); the lines above are the end of its log"
  fi
}

wait_ssh() {
  for _ in $(seq 1 40); do
    run "echo SSH''_OK" | grep -q SSH_OK && return
    sleep 10
  done
  fail "$VM does not answer over SSH"
}

# The VM's public IP (Multipass: its local IP), read from cmx vm info --json.
# The providers name the field differently (Jetstream: FloatingIP, Multipass: ip, AWS: IP), so the
# names are compared without case and underscores.
vm_ip() {
  COLUMNS=1000 cmx vm info "$VM" --json 2>/dev/null | sed -n '/^{/,/^}/p' | python3 -c '
import ipaddress, json, sys
info = {key.replace("_", "").lower(): value for key, value in json.load(sys.stdin).items()}
candidates = []
for key in ("floatingip", "publicip", "publicips", "ip", "ipv4", "networks", "privateips"):
    value = info.get(key)
    candidates += value if isinstance(value, list) else [value]
addresses = []
for value in candidates:
    try:
        addresses.append(ipaddress.ip_address(str(value)))
    except ValueError:
        pass
public = [a for a in addresses if not a.is_private]
best = public or addresses
print(best[0] if best else "")'
}

# The VM's state from cmx vm info (empty if it does not exist)
vm_state() {
  COLUMNS=1000 cmx vm info "$VM" --json 2>/dev/null | sed -n '/^{/,/^}/p' | python3 -c '
import json, sys
info = {key.lower(): value for key, value in json.load(sys.stdin).items()}
print(info.get("state") or info.get("status") or "")' 2>/dev/null || true
}

# Copy a small local file to the VM (base64 over cmx vm run); $3 is the owner on the VM, $4 the mode
put_file() {
  local src=$1 dest=$2 owner=${3:-} mode=${4:-600} data
  data=$(base64 < "$src" | tr -d '\n')
  run "mkdir -p \$(dirname $dest) && echo $data | base64 -d | sudo tee $dest > /dev/null && sudo chmod $mode $dest \
${owner:+&& sudo chown $owner $dest} && echo PUT''_OK" | grep -q PUT_OK || fail "could not copy $(basename "$src") to $VM"
}
