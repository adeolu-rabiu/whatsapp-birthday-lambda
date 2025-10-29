#!/bin/bash

echo "🔧 Fixing Node Exporter Connection"
echo "==================================="
echo ""

# 1. Update Prometheus config
echo "1️⃣ Updating Prometheus config..."
cat > monitoring/prometheus/prometheus.yml << 'PROM'
global:
  scrape_interval: 15s
  evaluation_interval: 30s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - /etc/prometheus/alerts.yml

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['prometheus:9090']

  - job_name: node
    static_configs:
      - targets: ['host.docker.internal:9100']

  - job_name: cadvisor
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: blackbox-http
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - http://wppconnect-bot:3005/health
          - http://python-api:5000/health
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox:9115
PROM

echo "✅ Config updated"

# 2. Add host.docker.internal to prometheus
echo ""
echo "2️⃣ Adding host gateway to Prometheus..."
python3 << 'PYTHON'
import yaml

with open('docker-compose.yml', 'r') as f:
    compose = yaml.safe_load(f)

# Add extra_hosts
if 'prometheus' in compose['services']:
    compose['services']['prometheus']['extra_hosts'] = ['host.docker.internal:host-gateway']

with open('docker-compose.yml', 'w') as f:
    yaml.dump(compose, f, default_flow_style=False, sort_keys=False)

print("✅ Added host.docker.internal")
PYTHON

# 3. Restart Prometheus
echo ""
echo "3️⃣ Restarting Prometheus..."
docker-compose stop prometheus
docker rm prometheus
docker-compose up -d prometheus

# 4. Wait and verify
echo ""
echo "4️⃣ Waiting 30 seconds for scrapes..."
sleep 30

# 5. Check final status
echo ""
echo "5️⃣ Final Target Status:"
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "  \(.labels.job): \(.health)"'

echo ""
echo "==================================="

# Check if all are up
all_up=$(curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | .health' | grep -c "up")
total=$(curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets | length')

if [ "$all_up" -eq "$total" ]; then
    echo "🎉 ALL TARGETS UP! ($all_up/$total)"
    echo ""
    echo "✅ Monitoring stack fully operational!"
    echo ""
    echo "📊 Next: Configure Grafana"
    echo "   Run: ./configure-grafana.sh"
else
    echo "⚠️  Some targets still down ($all_up/$total up)"
    echo ""
    echo "Check errors:"
    curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | select(.health != "up") | "  ❌ \(.labels.job): \(.lastError)"'
fi

