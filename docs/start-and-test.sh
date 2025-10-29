#!/bin/bash

echo "================================================"
echo "🚀 Starting WhatsApp Birthday Bot Services"
echo "================================================"
echo ""

# 1. Start Elasticsearch first (foundation for logging)
echo "1️⃣ Starting Elasticsearch..."
docker-compose up -d elasticsearch
sleep 15
docker-compose ps elasticsearch
echo ""

# 2. Start Python API
echo "2️⃣ Starting Python API..."
docker-compose up -d python-api
sleep 10
docker-compose ps python-api
echo ""

# 3. Start wppconnect-bot
echo "3️⃣ Starting wppconnect-bot..."
docker-compose up -d wppconnect-bot
sleep 15
docker-compose ps wppconnect-bot
echo ""

# 4. Start Web UI
echo "4️⃣ Starting Web UI..."
docker-compose up -d web-ui
sleep 10
docker-compose ps web-ui
echo ""

# 5. Start Dashboard
echo "5️⃣ Starting Dashboard..."
docker-compose up -d dashboard
sleep 10
docker-compose ps dashboard
echo ""

# 6. Start Kibana
echo "6️⃣ Starting Kibana..."
docker-compose up -d kibana
sleep 20
docker-compose ps kibana
echo ""

# 7. Start Filebeat
echo "7️⃣ Starting Filebeat..."
docker-compose up -d filebeat
sleep 5
docker-compose ps filebeat
echo ""

# 8. Start Metricbeat
echo "8️⃣ Starting Metricbeat..."
docker-compose up -d metricbeat
sleep 5
docker-compose ps metricbeat
echo ""

# 9. Start Cron
echo "9️⃣ Starting Cron..."
docker-compose up -d cron
sleep 5
docker-compose ps cron
echo ""

echo "================================================"
echo "✅ ALL SERVICES STARTED"
echo "================================================"
docker-compose ps
