#!/bin/bash

cd /opt/whatsapp-birthday-lambda

echo "════════════════════════════════════════════════════════"
echo "  Fixing All Monitoring Stack Containers"
echo "════════════════════════════════════════════════════════"
echo ""

# List of all monitoring containers
MONITORING_SERVICES="prometheus grafana alertmanager node-exporter cadvisor blackbox vmware-exporter"

echo "🛑 Step 1: Stopping all monitoring containers..."
for service in $MONITORING_SERVICES; do
    echo "  - Stopping $service..."
    docker-compose stop $service 2>/dev/null || true
done

echo ""
echo "🗑️ Step 2: Removing containers via docker-compose..."
for service in $MONITORING_SERVICES; do
    echo "  - Removing $service..."
    docker-compose rm -f $service 2>/dev/null || true
done

echo ""
echo "🧹 Step 3: Force removing any orphaned containers..."
# Remove by exact container names
docker rm -f prometheus grafana alertmanager node-exporter cadvisor blackbox vmware-exporter 2>/dev/null || true

# Remove by pattern (in case they have prefixes)
docker ps -a | grep -E "prometheus|grafana|alertmanager|node-exporter|cadvisor|blackbox|vmware-exporter" | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true

echo ""
echo "🧽 Step 4: Pruning dangling containers..."
docker container prune -f

echo ""
echo "📥 Step 5: Pulling fresh images..."
docker pull quay.io/prometheus/prometheus:v2.55.1
docker pull grafana/grafana:11.2.0
docker pull quay.io/prometheus/alertmanager:v0.27.0
docker pull quay.io/prometheus/node-exporter:v1.8.1
docker pull gcr.io/cadvisor/cadvisor:v0.49.1
docker pull quay.io/prometheus/blackbox-exporter:v0.25.0
docker pull pryorda/vmware_exporter:latest

echo ""
echo "🚀 Step 6: Starting monitoring stack in order..."
echo ""

echo "  📊 Starting Prometheus..."
docker-compose up -d prometheus
sleep 5

echo "  📈 Starting Grafana..."
docker-compose up -d grafana
sleep 5

echo "  🔔 Starting AlertManager..."
docker-compose up -d alertmanager
sleep 3

echo "  📡 Starting exporters..."
docker-compose up -d node-exporter cadvisor blackbox vmware-exporter
sleep 5

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Status Check"
echo "═══════════════════════════════════════════════════════"
echo ""
docker-compose ps prometheus grafana alertmanager node-exporter cadvisor blackbox vmware-exporter

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Service URLs (after containers are healthy)"
echo "═══════════════════════════════════════════════════════"
echo "  Prometheus:   http://localhost:9090"
echo "  Grafana:      http://localhost:3001 (admin/admin)"
echo "  AlertManager: http://localhost:9093"
echo "  Node Export:  http://localhost:9100/metrics"
echo "  cAdvisor:     http://localhost:8081"
echo "  Blackbox:     http://localhost:9115"
echo "  VMware Export: http://localhost:9272"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "✅ Done! Monitor logs with: docker-compose logs -f prometheus grafana"
EOF

chmod +x /tmp/fix_all_monitoring.sh
cat /tmp/fix_all_monitoring.sh
Output

#!/bin/bash

cd /opt/whatsapp-birthday-lambda

echo "════════════════════════════════════════════════════════"
echo "  Fixing All Monitoring Stack Containers"
echo "════════════════════════════════════════════════════════"
echo ""

# List of all monitoring containers
MONITORING_SERVICES="prometheus grafana alertmanager node-exporter cadvisor blackbox vmware-exporter"

echo "🛑 Step 1: Stopping all monitoring containers..."
for service in $MONITORING_SERVICES; do
    echo "  - Stopping $service..."
    docker-compose stop $service 2>/dev/null || true
done

echo ""
echo "🗑️ Step 2: Removing containers via docker-compose..."
for service in $MONITORING_SERVICES; do
    echo "  - Removing $service..."
    docker-compose rm -f $service 2>/dev/null || true
done

echo ""
echo "🧹 Step 3: Force removing any orphaned containers..."
# Remove by exact container names
docker rm -f prometheus grafana alertmanager node-exporter cadvisor blackbox vmware-exporter 2>/dev/null || true

# Remove by pattern (in case they have prefixes)
docker ps -a | grep -E "prometheus|grafana|alertmanager|node-exporter|cadvisor|blackbox|vmware-exporter" | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true

echo ""
echo "🧽 Step 4: Pruning dangling containers..."
docker container prune -f

echo ""
echo "📥 Step 5: Pulling fresh images..."
docker pull quay.io/prometheus/prometheus:v2.55.1
docker pull grafana/grafana:11.2.0
docker pull quay.io/prometheus/alertmanager:v0.27.0
docker pull quay.io/prometheus/node-exporter:v1.8.1
docker pull gcr.io/cadvisor/cadvisor:v0.49.1
docker pull quay.io/prometheus/blackbox-exporter:v0.25.0
docker pull pryorda/vmware_exporter:latest

echo ""
echo "🚀 Step 6: Starting monitoring stack in order..."
echo ""

echo "  📊 Starting Prometheus..."
docker-compose up -d prometheus
sleep 5

echo "  📈 Starting Grafana..."
docker-compose up -d grafana
sleep 5

echo "  �� Starting AlertManager..."
docker-compose up -d alertmanager
sleep 3

echo "  📡 Starting exporters..."
docker-compose up -d node-exporter cadvisor blackbox vmware-exporter
sleep 5

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Status Check"
echo "═══════════════════════════════════════════════════════"
echo ""
docker-compose ps prometheus grafana alertmanager node-exporter cadvisor blackbox vmware-exporter

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Service URLs (after containers are healthy)"
echo "═══════════════════════════════════════════════════════"
echo "  Prometheus:   http://localhost:9090"
echo "  Grafana:      http://localhost:3001 (admin/admin)"
echo "  AlertManager: http://localhost:9093"
echo "  Node Export:  http://localhost:9100/metrics"
echo "  cAdvisor:     http://localhost:8081"
echo "  Blackbox:     http://localhost:9115"
echo "  VMware Export: http://localhost:9272"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "✅ Done! Monitor logs with: docker-compose logs -f prometheus grafana"
