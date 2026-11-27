#!/usr/bin/env bash
# Deploy and run InferScale on one cloud with cmx vm. Run it on the laptop, in the cmx virtual environment.
#   ./deploy.sh deploy  <cloud>   create the VM, install Docker, get the code, make the secrets, build the images
#   ./deploy.sh start   <cloud>   start the containers and wait until the service answers over HTTPS
#   ./deploy.sh demo    <cloud>   send example requests as the client account
#   ./deploy.sh load    <cloud>   load test with Locust (USERS=10, DURATION=60s); results in results/<cloud>/
#   ./deploy.sh stop    <cloud>   stop the containers (the VM and the data stay)
#   ./deploy.sh destroy <cloud>   save the logs and a database export to results/<cloud>/, then delete the VM
# <cloud> is multipass, jetstream or aws (chameleon also works). Or: make deploy|start|demo|load|stop|destroy CLOUD=<cloud>
set -euo pipefail

usage() { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
[ $# -eq 2 ] || usage
ACTION=$1
export OS_CLOUD=$2                     # every cmx command uses this cloud; clouds.yaml is not changed
case $ACTION in deploy | start | demo | load | stop | destroy) ;; *) usage ;; esac
case $OS_CLOUD in multipass | jetstream | aws | chameleon) ;; *) usage ;; esac

HERE=$(cd "$(dirname "$0")" && pwd)
VM=${VM:-inferscale-shabbir04}         # a unique name: Jetstream and Chameleon projects are shared by the class
REPO=https://github.com/cloudmesh-ai-luc/shabbir04.git
CONFIG=$HOME/.config/inferscale        # passwords, certificates and state; outside Git
CERT=$CONFIG/certs/$OS_CLOUD.pem       # the VM's certificate, fetched over SSH and checked on every call
STATE=$CONFIG/clouds/$OS_CLOUD.env     # name and IP of the deployed VM
HOURS=${HOURS:-3}                      # length of the Chameleon lease

command -v cmx >/dev/null || { echo "cmx not found: activate the cloudmesh-ai-vm virtual environment first"; exit 1; }
# cmx vm run passes the public key file to ssh -i on OpenStack clouds (cmx issue #131), so ssh can only
# log in with a key from the SSH agent. Load it once per login session: ssh-add ~/.ssh/id_ed25519
if { [ "$OS_CLOUD" = jetstream ] || [ "$OS_CLOUD" = chameleon ]; } && ! ssh-add -l >/dev/null 2>&1; then
  echo "The SSH agent has no key: run  ssh-add ~/.ssh/id_ed25519  first (needed until cmx #131 is fixed)"
  exit 1
fi
mkdir -p "$CONFIG/certs" "$CONFIG/clouds" && chmod 700 "$CONFIG"

# Shared helpers: log, fail, run, run_long, wait_ssh, vm_ip, vm_state, put_file, INSTALL_DOCKER
. "$HERE/tools/cmx.sh"

load_state() {
  [ -f "$STATE" ] || fail "no deployment on $OS_CLOUD yet: run make deploy CLOUD=$OS_CLOUD first"
  # shellcheck source=/dev/null
  . "$STATE"
}

# Call the service as one account; the password is passed on stdin, never on the command line
api() {
  local account=$1; shift
  curl -sS --cacert "$CERT" -K - "$@" <<EOF
user = "$account:$(cat "$CONFIG/$account.password")"
EOF
}

# Port 443 for this laptop only. AWS: the security group in clouds.yaml already allows 22 and 443 from
# my IP. Multipass: the VM can only be reached from this Mac. Jetstream, Chameleon: one extra security group.
open_https() {
  case $OS_CLOUD in jetstream | chameleon) ;; *) return 0 ;; esac
  local group=$VM-https myip reply
  myip=$(curl -s https://checkip.amazonaws.com | tr -d '[:space:]')
  # Create the group only once: OpenStack allows several groups with the same name, and then adding
  # the group to the VM by its name fails.
  if ! COLUMNS=1000 cmx vm security-group list 2>/dev/null | grep -q -E "(^|[^[:alnum:]_-])$group([^[:alnum:]_-]|$)"; then
    cmx vm security-group create "$group" --description "InferScale: HTTPS from my IP only" > /dev/null
  fi
  cmx vm security-group rule add "$group" --protocol tcp --port 443 --cidr "$myip/32" > /dev/null 2>&1 || true  # may exist
  cmx vm security-group add "$VM" "$group" > /dev/null 2>&1 || true   # may already be on the VM
  # Check that the firewall really lets this laptop through. Nothing listens on port 443 yet, so an open
  # port answers "refused" at once, while a closed firewall drops the packets (a timeout).
  for _ in 1 2 3 4 5 6; do
    reply=$(nc -z -v -G 5 "$IP" 443 2>&1 || true)
    case $reply in *refused* | *succeeded*)
      echo "Port 443 open for $myip only (security group $group)"; return ;;
    esac
    sleep 5
  done
  fail "port 443 on $IP is still closed for $myip: check the security group $group"
}

fetch_cert() {
  run "cat inferscale/secrets/tls.crt" | sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' > "$CERT"
  grep -q 'END CERTIFICATE' "$CERT" || fail "could not fetch the certificate from $VM"
}

deploy() {
  local start_time=$SECONDS
  log "1/6 Create the VM $VM on $OS_CLOUD with cmx"
  local state
  state=$(vm_state)
  case $state in
    ACTIVE | active | Running | running)
      # running already (for example a second make deploy): reuse it, never make a second VM with this name
      echo "$VM is already running ($state); using it" ;;
    *)
      case $OS_CLOUD in
        jetstream) cmx vm start "$VM" ;;                         # also assigns a floating IP
        aws) cmx vm start "$VM" --noip ;;                        # public IP from the subnet, no paid Elastic IP
        multipass) cmx vm start "$VM" ;;                         # also resumes a stopped VM
        chameleon) cmx vm start "$VM" --duration "${HOURS}h" ;;   # also creates the lease and a floating IP
      esac ;;
  esac
  wait_ssh
  IP=$(vm_ip)
  [ -n "$IP" ] || fail "cmx shows no IP for $VM"
  printf 'VM=%s\nIP=%s\n' "$VM" "$IP" > "$STATE"
  echo "$VM has the IP $IP"

  log "2/6 Open HTTPS (port 443) for this laptop"
  open_https

  log "3/6 Install Docker and get the code (on the VM)"
  run_long install "$INSTALL_DOCKER
if [ -d inferscale ]; then git -C inferscale pull -q; else git clone -q --depth 1 $REPO inferscale; fi"

  log "4/6 Certificate (made on the VM) and password hashes (made on this laptop)"
  run "cd inferscale && make certs IP=$IP > /dev/null 2>&1 && echo CERT''_OK" | grep -q CERT_OK || fail "make certs failed"
  make -s -C "$HERE" passwords
  local h1 h2
  h1=$(base64 < "$CONFIG/htpasswd" | tr -d '\n')
  h2=$(base64 < "$CONFIG/metrics.htpasswd" | tr -d '\n')
  run "cd inferscale/secrets && echo $h1 | base64 -d | sudo tee htpasswd > /dev/null && \
echo $h2 | base64 -d | sudo tee metrics.htpasswd > /dev/null && echo HASH''_OK" | grep -q HASH_OK || fail "copying the hashes failed"

  log "5/6 Build the images on the VM (a few minutes)"
  # the build cache is not needed after the build; removing it keeps room on small disks (AWS: 8 GB)
  run_long image "cd inferscale && make image && docker builder prune -af > /dev/null"

  log "6/6 Save the VM's certificate on this laptop"
  fetch_cert
  echo "Deployed on $OS_CLOUD in $(( (SECONDS - start_time) / 60 )) min. Next: make start CLOUD=$OS_CLOUD"
}

start() {
  load_state
  local start_time=$SECONDS
  log "Start the containers on $VM ($OS_CLOUD)"
  run_long up "cd inferscale && make up"
  fetch_cert
  log "Wait until https://$IP answers"
  for _ in $(seq 1 30); do
    # time limits, so a closed firewall cannot stretch the 5-minute wait
    if api client -f -o /dev/null --connect-timeout 5 --max-time 15 "https://$IP/api/health" 2>/dev/null; then
      echo "InferScale is up on $OS_CLOUD after $((SECONDS - start_time)) s: https://$IP"
      echo "Log in as demo; copy its password with: pbcopy < $CONFIG/demo.password"
      "$HERE/monitor.sh" targets || true    # Prometheus watches this cloud from now on
      return
    fi
    sleep 10
  done
  fail "https://$IP/api/health did not answer in 5 minutes"
}

demo() {
  load_state
  local json='Content-Type: application/json'
  log "Demo on $OS_CLOUD (https://$IP), as the client account"
  echo "Analyze a review:"
  api client -H "$json" -d '{"text":"The battery lasts all day and the screen is beautiful."}' "https://$IP/api/predict"; echo
  echo "Analyze another review:"
  api client -H "$json" -d '{"text":"It stopped working after two days and support never answered."}' "https://$IP/api/predict"; echo
  echo "Keep only the confident negative reviews:"
  api client -H "$json" -d '{"texts":["Great value for the price","Broke on the first day","Arrived late and damaged","Works as described"]}' "https://$IP/api/filter"; echo
  echo "History of the client account:"
  api client "https://$IP/api/history?limit=3"; echo
  echo "Without a login: HTTP $(curl -s -o /dev/null -w '%{http_code}' --cacert "$CERT" "https://$IP/api/health")"
}

load() {
  load_state
  local locust=$HERE/.venv/bin/locust out
  [ -x "$locust" ] || fail "Locust is not installed: run  .venv/bin/pip install -e '.[load]'  in this project"
  out=$HERE/results/$OS_CLOUD/$(date +%Y%m%d-%H%M%S)-load
  mkdir -p "$(dirname "$out")"
  log "Load test on $OS_CLOUD (https://$IP): ${USERS:-10} users for ${DURATION:-60s}, from this laptop"
  CLOUD=$OS_CLOUD "$locust" -f "$HERE/tools/loadtest.py" --headless --only-summary \
    -u "${USERS:-10}" -r 2 -t "${DURATION:-60s}" --host "https://$IP" --csv "$out" > "$out.log" 2>&1 || true
  [ -f "${out}_stats.csv" ] || fail "Locust wrote no results; see ${out#"$HERE"/}.log"
  python3 - "${out}_stats.csv" "$OS_CLOUD" <<'EOF'
import csv, sys
rows = {r["Name"]: r for r in csv.DictReader(open(sys.argv[1]))}
print(f"{'':16}{'requests':>9}{'failed':>8}{'req/s':>7}{'p50 ms':>8}{'p95 ms':>8}{'p99 ms':>8}")
for name in ("/api/predict", "/api/history", "Aggregated"):
    r = rows.get(name)
    if r:
        print(f"{name:16}{r['Request Count']:>9}{r['Failure Count']:>8}{float(r['Requests/s']):>7.1f}"
              f"{r['50%']:>8}{r['95%']:>8}{r['99%']:>8}")
EOF
  echo "CSV files: ${out#"$HERE"/}_stats.csv (and _stats_history.csv, _failures.csv)"
}

stop() {
  load_state
  log "Stop the containers on $VM ($OS_CLOUD); the VM and the data stay"
  run_long down "cd inferscale && make down"
}

destroy() {
  load_state
  local out
  out=$HERE/results/$OS_CLOUD/$(date +%Y%m%d-%H%M%S)
  mkdir -p "$out"
  log "Save the container logs and a database export to ${out#"$HERE"/}"
  run_long export "cd inferscale
docker compose logs --no-color > ~/export-logs.txt 2>&1 || true
docker compose exec -T db pg_dump -U inferscale inferscale | gzip > ~/export-db.sql.gz || true"
  for file in logs.txt db.sql.gz; do
    run "echo BEGIN; base64 -w 76 ~/export-$file 2>/dev/null; echo END" \
      | sed -n '/^BEGIN$/,/^END$/p' | sed '1d;$d' | base64 -d > "$out/$file" || true
  done
  ls -l "$out"
  log "Delete the VM $VM with cmx"
  cmx vm delete "$VM"
  release_leftover_ip
  rm -f "$STATE" "$CERT"
  "$HERE/monitor.sh" targets || true      # stop watching it, so there is no false CloudDown alert
  echo "Deleted. Check that nothing is left with: cmx vm list"
}

# On Jetstream, cmx vm delete keeps the floating IP (release_floating_ip reads libcloud's public_ips,
# which openstacksdk servers do not have). Until that is fixed in cmx, release it here so it is not
# left reserved in the shared project.
release_leftover_ip() {
  [ "$OS_CLOUD" = jetstream ] || return 0
  python3 - "$IP" <<'EOF'
import sys, time
import openstack
conn = openstack.connect(cloud="jetstream")
for _ in range(12):  # the IP is detached when the server is gone
    ips = list(conn.network.ips(floating_ip_address=sys.argv[1]))
    if not ips or not ips[0].port_id:
        break
    time.sleep(5)
for fip in ips:
    if not fip.port_id:
        conn.network.delete_ip(fip)
        print("Released the floating IP", fip.floating_ip_address)
EOF
}

"$ACTION"
