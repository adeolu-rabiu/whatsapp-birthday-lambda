#!/bin/bash

cd /opt/whatsapp-birthday-lambda

echo "🛑 Stopping and removing old Prometheus container..."
docker-compose stop prometheus
docker-compose rm -f prometheus

echo "🗑️ Removing orphaned Prometheus container if exists..."
docker rm -f ff74dc83c043_prometheus 2>/dev/null || true
docker rm -f prometheus 2>/dev/null || true

echo "🧹 Cleaning up any dangling containers..."
docker container prune -f

echo "📥 Pulling fresh Prometheus image..."
docker pull quay.io/prometheus/prometheus:v2.55.1

echo "🚀 Starting Prometheus with fresh container..."
docker-compose up -d prometheus

echo ""
echo "⏳ Waiting 5 seconds..."
sleep 5

echo ""
echo "📊 Checking Prometheus status..."
docker-compose ps prometheus

echo ""
echo "📋 Recent logs:"
docker-compose logs --tail=20 prometheus

echo ""
echo "✅ Done! Check if Prometheus is running at http://localhost:9090"
