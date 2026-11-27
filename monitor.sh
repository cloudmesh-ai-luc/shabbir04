#!/usr/bin/env bash
# Prometheus + Grafana for InferScale in a local Multipass VM made with cmx. Run it on the laptop, in the
# cmx virtual environment. It watches every cloud that make deploy and make start have set up.
#   ./monitor.sh start     create the VM if needed, then start Prometheus and Grafana
#   ./monitor.sh targets   update which clouds Prometheus watches (make start and make destroy call this)
#   ./monitor.sh stop      stop Prometheus and Grafana (the collected data stays)
#   ./monitor.sh destroy   delete the monitoring VM
# Or: make monitor, make monitor-stop, make monitor-destroy
set -euo pipefail

usage() { sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
[ $# -eq 1 ] || usage
ACTION=$1
case $ACTION in start | targets | stop | destroy) ;; *) usage ;; esac

HERE=$(cd "$(dirname "$0")" && pwd)
export OS_CLOUD=multipass             # the monitoring VM is always local
VM=${MONITOR_VM:-inferscale-monitor}
CONFIG=$HOME/.config/inferscale       # passwords, certificates and the deployed clouds (*.env); outside Git
# Shared helpers: log, fail, run, run_long, wait_ssh, vm_ip, vm_state, put_file, INSTALL_DOCKER
. "$HERE/tools/cmx.sh"

# cmx comes from the cloudmesh-ai-vm virtual environment; if it is not activated, use the class layout
CMX_VENV=${CMX_VENV:-$HOME/work/cloudmesh-ai-vm/.venv}
command -v cmx > /dev/null || { [ -x "$CMX_VENV/bin/cmx" ] && PATH="$CMX_VENV/bin:$PATH"; }
command -v cmx >/dev/null || fail "cmx not found: activate the cloudmesh-ai-vm virtual environment, or set CMX_VENV"

running() { case $(vm_state) in Running | running) return 0 ;; *) return 1 ;; esac; }

# The monitoring/ files without secrets, copied as one compressed archive
copy_config() {
  local data
  data=$(cd "$HERE" && COPYFILE_DISABLE=1 tar --no-xattrs -czf - monitoring/compose.yaml \
    monitoring/prometheus/prometheus.yml monitoring/prometheus/alerts.yml monitoring/grafana | base64 | tr -d '\n')
  run "echo $data | base64 -d | tar -xzf - 2>/dev/null; mkdir -p monitoring/prometheus/scrape && echo COPY''_OK" \
    | grep -q COPY_OK || fail "could not copy the monitoring configuration to $VM"
}

# One scrape file per deployed cloud (its IP and certificate), then reload Prometheus
update_targets() {
  local state cloud ip file clouds=""
  put_file "$CONFIG/prometheus.password" monitoring/secrets/prometheus/prometheus.password 65534
  run "rm -f monitoring/prometheus/scrape/*.yml" > /dev/null
  file=$(mktemp)
  for state in "$CONFIG"/clouds/*.env; do
    [ -f "$state" ] || continue
    cloud=$(basename "$state" .env)
    ip=$(sed -n 's/^IP=//p' "$state")
    [ -n "$ip" ] && [ -f "$CONFIG/certs/$cloud.pem" ] || continue
    put_file "$CONFIG/certs/$cloud.pem" "monitoring/secrets/prometheus/$cloud.pem" 65534
    cat > "$file" <<EOF
# written by monitor.sh for the InferScale deployment on $cloud
scrape_configs:
  - job_name: $cloud
    scheme: https
    metrics_path: /api/metrics
    basic_auth:
      username: prometheus
      password_file: /etc/prometheus-secrets/prometheus.password
    tls_config:
      ca_file: /etc/prometheus-secrets/$cloud.pem
    static_configs:
      - targets: ["$ip:443"]
        labels:
          cloud: $cloud
EOF
    put_file "$file" "monitoring/prometheus/scrape/$cloud.yml" "" 644
    clouds="$clouds $cloud"
  done
  rm -f "$file"
  # SIGHUP makes Prometheus read its configuration again
  run "cd monitoring && docker compose kill -s SIGHUP prometheus > /dev/null 2>&1; echo RELOADED" > /dev/null
  echo "Prometheus watches:${clouds:- no cloud yet (make deploy and make start first)}"
}

start() {
  log "Monitoring VM $VM (Multipass) with cmx"
  running || cmx vm start "$VM"
  wait_ssh
  # a marker, not the word "docker": cmx repeats a failed command (with the word in it) in its error message
  if ! run "command -v docker > /dev/null && echo HAVE''_DOCKER" | grep -q HAVE_DOCKER; then
    log "Install Docker (on the VM)"
    run_long monitor-install "$INSTALL_DOCKER"
  fi

  log "Copy the configuration, the passwords and the clouds' certificates"
  copy_config
  make -s -C "$HERE" passwords
  [ -f "$CONFIG/grafana-admin.password" ] || (umask 077 && openssl rand -base64 24 > "$CONFIG/grafana-admin.password")
  put_file "$CONFIG/grafana-admin.password" monitoring/secrets/grafana/grafana-admin.password 472

  log "Start Prometheus and Grafana"
  run_long monitor-up "cd monitoring && docker compose up -d"
  update_targets

  local ip
  ip=$(vm_ip)
  echo
  echo "Grafana:    http://$ip:3000/d/inferscale  (user admin; copy its password: pbcopy < $CONFIG/grafana-admin.password)"
  echo "Prometheus: http://$ip:9090/alerts"
}

targets() {
  if running; then update_targets; else echo "Monitoring is not running (make monitor starts it)"; fi
}

stop() {
  log "Stop Prometheus and Grafana on $VM; the data stays"
  run_long monitor-down "cd monitoring && docker compose stop"
}

destroy() {
  log "Delete the monitoring VM $VM with cmx"
  cmx vm delete "$VM"
}

"$ACTION"
