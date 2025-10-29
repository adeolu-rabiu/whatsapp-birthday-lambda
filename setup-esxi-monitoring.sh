#!/bin/bash
set -euo pipefail

echo "🌡️ Setting Up ESXi Monitoring (vmware_exporter)"
echo "================================================"
echo ""

# sanity checks
if [[ ! -f docker-compose.yml ]]; then
  echo "❌ docker-compose.yml not found in $(pwd)"; exit 1
fi

if [[ ! -f .env ]]; then
  echo "⚠️  .env not found — creating placeholders for ESXi vars"
  cat >> .env <<'ENVVARS'

# --- ESXi / vCenter for vmware_exporter ---
VSPHERE_HOST=CHANGE_ME_ESXI_IP
VSPHERE_USER=root
VSPHERE_PASSWORD=CHANGE_ME_PASSWORD
VSPHERE_IGNORE_SSL=True
ENVVARS
fi

# ensure required keys exist (append if missing)
for k in VSPHERE_HOST VSPHERE_USER VSPHERE_PASSWORD VSPHERE_IGNORE_SSL; do
  if ! grep -qE "^\s*${k}=" .env; then
    echo "${k}=CHANGE_ME" >> .env
    echo "➕ Added ${k}=CHANGE_ME to .env"
  fi
done

echo "1️⃣ Adding/Updating vmware-exporter service in docker-compose.yml ..."
python3 - << 'PY'
import sys, yaml
from pathlib import Path

compose_path = Path("docker-compose.yml")
data = yaml.safe_load(compose_path.read_text())

services = data.setdefault("services", {})

services["vmware-exporter"] = {
    "image": "pryorda/vmware_exporter:latest",
    "container_name": "vmware-exporter",
    # read secrets from .env
    "env_file": [".env"],
    # pass-through variable references (resolved by docker compose from .env)
    "environment": {
        "VSPHERE_HOST": "${VSPHERE_HOST}",
        "VSPHERE_USER": "${VSPHERE_USER}",
        "VSPHERE_PASSWORD": "${VSPHERE_PASSWORD}",
        "VSPHERE_IGNORE_SSL": "${VSPHERE_IGNORE_SSL}"
    },
    "ports": ["9272:9272"],
    "networks": ["birthday-network"],
    "restart": "unless-stopped"
}

compose_path.write_text(yaml.dump(data, sort_keys=False))
print("✅ vmware-exporter service written")
PY

# Prometheus scrape config (idempotent add)
PROM_FILE="monitoring/prometheus/prometheus.yml"
mkdir -p monitoring/prometheus

if [[ -f "$PROM_FILE" ]] && grep -q 'job_name:\s*esxi' "$PROM_FILE"; then
  echo "ℹ️  Prometheus job 'esxi' already present — skipping add."
else
  echo "2️⃣ Adding Prometheus 'esxi' scrape job to $PROM_FILE ..."
  # make sure file exists and ends with newline
  touch "$PROM_FILE"
  [[ -s "$PROM_FILE" ]] && tail -c1 "$PROM_FILE" | read -r _ || echo "" >> "$PROM_FILE"

  cat >> "$PROM_FILE" <<'PROM'

  # ESXi Host Metrics
  - job_name: esxi
    static_configs:
      - targets: ['vmware-exporter:9272']
PROM
  echo "✅ Added Prometheus job 'esxi'."
fi

echo ""
echo "Next steps:"
echo "  1) Open .env and set real values for VSPHERE_HOST and VSPHERE_PASSWORD."
echo "  2) Start the exporter and reload Prometheus:"
echo "     docker compose up -d vmware-exporter"
echo "     docker compose restart prometheus"
echo ""
echo "🎯 Grafana tip: add Prometheus as a data source (http://prometheus:9090) and import any ESXi/vSphere dashboards."
