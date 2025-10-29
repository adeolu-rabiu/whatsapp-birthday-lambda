#!/bin/bash
set -e

echo "🔍 Verifying ESXi Monitoring"
echo "============================="
echo ""

echo "1️⃣ VMware Exporter Container:"
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E '^vmware-exporter' || { echo "❌ Not running"; exit 1; }
echo "   ✅ Running"

echo ""
echo "2️⃣ Recent Logs:"
docker logs vmware-exporter --tail 10 || true

echo ""
echo "3️⃣ Available ESXi Metrics (sample):"
curl -s http://localhost:9272/metrics | grep '^vmware_' | cut -d'{' -f1 | sort -u | head -20

echo ""
echo "4️⃣ Temperature Lines:"
curl -s http://localhost:9272/metrics | grep -i 'temperature' || echo "No temperature sensors found"

echo ""
echo "5️⃣ Prometheus Targets:"
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.job) - \(.labels.instance): \(.health)"' || true

echo ""
echo "✅ Verification complete."
