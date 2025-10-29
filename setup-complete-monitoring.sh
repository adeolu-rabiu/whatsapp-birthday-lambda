#!/bin/bash

echo "🎯 Setting Up Complete Monitoring System"
echo "=========================================="
echo ""

# 1. Fix node-exporter network access
echo "1️⃣ Updating docker-compose for better metrics..."
python3 << 'PYTHON'
import yaml

with open('docker-compose.yml', 'r') as f:
    compose = yaml.safe_load(f)

# Update node-exporter to expose port properly
compose['services']['node-exporter']['ports'] = ['9100:9100']

with open('docker-compose.yml', 'w') as f:
    yaml.dump(compose, f, default_flow_style=False, sort_keys=False)

print("✅ Updated docker-compose.yml")
PYTHON

# 2. Update Prometheus config for all metrics
echo ""
echo "2️⃣ Updating Prometheus configuration..."
cat > monitoring/prometheus/prometheus.yml << 'PROM'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - /etc/prometheus/alerts.yml

scrape_configs:
  # Prometheus itself
  - job_name: prometheus
    static_configs:
      - targets: ['prometheus:9090']

  # Node Exporter - VM metrics (RAM, disk, CPU, etc)
  - job_name: node
    static_configs:
      - targets: ['192.168.1.66:9100']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        replacement: 'whatsapp-vm'

  # cAdvisor - Container metrics
  - job_name: cadvisor
    static_configs:
      - targets: ['cadvisor:8080']

  # Application health checks
  - job_name: blackbox-http
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - http://wppconnect-bot:3005/health
          - http://python-api:5000/health
          - http://dashboard:8080/health
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox:9115

  # Python API custom metrics (we'll add this)
  - job_name: birthday-bot-api
    static_configs:
      - targets: ['python-api:5000']
    metrics_path: /metrics
PROM

echo "✅ Prometheus config updated"

# 3. Restart services
echo ""
echo "3️⃣ Restarting monitoring services..."
docker-compose restart node-exporter prometheus
sleep 20

# 4. Check status
echo ""
echo "4️⃣ Checking metrics availability..."
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.job): \(.health)"'

echo ""
echo "=========================================="
echo "✅ Setup complete!"

