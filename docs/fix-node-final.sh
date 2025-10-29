#!/bin/bash

echo "🔧 Final Node Exporter Fix"
echo "=========================="
echo ""

# 1. Get gateway IP
echo "1️⃣ Getting Docker gateway IP..."
GATEWAY_IP=$(docker network inspect whatsapp-birthday-lambda_birthday-network | jq -r '.[0].IPAM.Config[0].Gateway')
echo "   Gateway IP: $GATEWAY_IP"

if [ -z "$GATEWAY_IP" ] || [ "$GATEWAY_IP" = "null" ]; then
    echo "   ❌ Could not get gateway IP"
    echo "   Using default: 172.18.0.1"
    GATEWAY_IP="172.18.0.1"
fi

# 2. Test if node-exporter is reachable from gateway
echo ""
echo "2️⃣ Testing node-exporter from container..."
docker run --rm --network whatsapp-birthday-lambda_birthday-network alpine/curl -s "http://${GATEWAY_IP}:9100/metrics" | head -5 && echo "✅ Reachable" || echo "⚠️ Not reachable"

# 3. Update Prometheus config
echo ""
echo "3️⃣ Updating Prometheus config with gateway IP..."
cat > monitoring/prometheus/prometheus.yml << EOF
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
      - targets: ['${GATEWAY_IP}:9100']

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
EOF

echo "✅ Config updated with ${GATEWAY_IP}:9100"

# 4. Restart Prometheus
echo ""
echo "4️⃣ Restarting Prometheus..."
docker-compose restart prometheus

# 5. Wait and verify
echo ""
echo "5️⃣ Waiting 30 seconds..."
sleep 30

# 6. Check status
echo ""
echo "6️⃣ Final Target Status:"
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "  \(.labels.job): \(.health)"'

# Check if all up
echo ""
all_up=$(curl -s http://localhost:9090/api/v1/targets | jq -r '[.data.activeTargets[] | select(.health == "up")] | length')
total=$(curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets | length')

if [ "$all_up" -eq "$total" ]; then
    echo "=========================="
    echo "🎉 SUCCESS! All targets UP!"
    echo ""
    echo "📊 Ready for Grafana setup!"
else
    echo "=========================="
    echo "⚠️ Still have issues ($all_up/$total up)"
    echo ""
    echo "Checking errors:"
    curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | select(.health != "up") | "  ❌ \(.labels.job): \(.lastError)"'
fi

