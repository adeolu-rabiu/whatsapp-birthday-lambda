#!/bin/bash

echo "================================"
echo "📊 COMPLETE SYSTEM HEALTH CHECK"
echo "================================"
echo ""

echo "✅ Core Services:"
echo "  - Python API:      $(curl -s http://localhost:5000/health >/dev/null 2>&1 && echo '🟢 OK' || echo '🔴 DOWN')"
echo "  - wppconnect-bot:  $(curl -s http://localhost:3005/health >/dev/null 2>&1 && echo '🟢 OK' || echo '🔴 DOWN')"
echo "  - Web UI:          $(curl -s -o /dev/null -w '%{http_code}' http://localhost:3000 2>/dev/null | grep -q 200 && echo '🟢 OK' || echo '🔴 DOWN')"

echo ""
echo "📈 Monitoring Services:"
echo "  - Dashboard:       $(curl -s http://localhost:8080/health >/dev/null 2>&1 && echo '🟢 OK' || echo '🔴 DOWN')"
echo "  - Elasticsearch:   $(curl -s http://localhost:9200/_cluster/health >/dev/null 2>&1 && echo '🟢 OK' || echo '🔴 DOWN')"
echo "  - Kibana:          $(curl -s -o /dev/null -w '%{http_code}' http://localhost:5601 2>/dev/null | grep -q 302 && echo '🟢 OK' || echo '🔴 DOWN')"

echo ""
echo "🔧 Background Services:"
docker ps | grep -q filebeat && echo "  - Filebeat:        🟢 Running" || echo "  - Filebeat:        🔴 Down"
docker ps | grep -q metricbeat && echo "  - Metricbeat:      🟢 Running" || echo "  - Metricbeat:      🔴 Down"
docker ps | grep -q "whatsapp-birthday-lambda_cron" && echo "  - Cron:            🟢 Running" || echo "  - Cron:            🔴 Down"

echo ""
echo "================================"
echo "📱 WhatsApp Status"
echo "================================"

# Check WhatsApp connection
wpp_status=$(curl -s http://localhost:3005/health | jq -r '.ok' 2>/dev/null)
if [ "$wpp_status" = "true" ]; then
    echo "Status: 🟢 Connected"
    
    # List groups
    echo ""
    echo "Available Groups:"
    curl -s http://localhost:3005/groups | jq -r '.groups[]?.name' 2>/dev/null | while read group; do
        echo "  • $group"
    done
else
    echo "Status: 🔴 Not Connected"
fi

echo ""
echo "================================"
echo "⏰ Cron Job Status"
echo "================================"
docker exec whatsapp-birthday-lambda_cron crontab -l 2>/dev/null || echo "Cron container not accessible"

echo ""
echo "Last Cron Execution:"
docker exec whatsapp-birthday-lambda_cron tail -10 /app/logs/cron.log 2>/dev/null || echo "No logs yet"

echo ""
echo "================================"
echo "🌐 Access URLs"
echo "================================"
echo "  Web UI:       http://localhost:3000"
echo "  Python API:   http://localhost:5000"
echo "  WhatsApp Bot: http://localhost:3005"
echo "  Dashboard:    http://localhost:8080"
echo "  Kibana:       http://localhost:5601"
echo ""
