#!/bin/bash
set -euo pipefail

echo "2️⃣ Adding VMware exporter to docker-compose.yml..."

python3 << 'PYTHON'
import yaml, sys

with open('docker-compose.yml','r') as f:
    compose = yaml.safe_load(f)

services = compose.setdefault('services', {})

services['vmware-exporter'] = {
    'image': 'pryorda/vmware_exporter:latest',
    'container_name': 'vmware-exporter',
    # Compose will expand ${VSPHERE_*} from the project .env file
    'environment': [
        'VSPHERE_HOST=${VSPHERE_HOST}',
        'VSPHERE_USER=${VSPHERE_USER}',
        'VSPHERE_PASSWORD=${VSPHERE_PASSWORD}',
        'VSPHERE_IGNORE_SSL=${VSPHERE_IGNORE_SSL:-true}'
    ],
    'ports': ['9272:9272'],
    'networks': ['birthday-network'],
    'restart': 'unless-stopped'
}

with open('docker-compose.yml','w') as f:
    yaml.dump(compose, f, default_flow_style=False, sort_keys=False)

print("✅ Added vmware-exporter to docker-compose.yml")
PYTHON

echo ""
echo "3️⃣ Updating Prometheus configuration..."
if ! grep -q "job_name: esxi" monitoring/prometheus/prometheus.yml; then
  cat >> monitoring/prometheus/prometheus.yml << 'PROM'

  # ESXi Host Metrics
  - job_name: esxi
    static_configs:
      - targets: ['vmware-exporter:9272']
PROM
  echo "✅ Added ESXi job to Prometheus config"
else
  echo "⚠️ ESXi job already exists"
fi

echo ""
echo "Next:"
echo "  docker compose up -d vmware-exporter"
echo "  docker compose restart prometheus"
echo "  curl -s http://localhost:9272/metrics | grep -i vmware || true"
