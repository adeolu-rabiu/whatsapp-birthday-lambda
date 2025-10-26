#!/bin/bash

echo "================================================"
echo "🏥 COMPLETE SYSTEM HEALTH CHECK"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

test_service() {
    local name=$1
    local test=$2
    echo -n "  - $name: "
    if eval "$test" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ DOWN${NC}"
        return 1
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Core Application Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

test_service "Python API        " "curl -s http://localhost:5000/health | jq -e '.status == \"ok\"'"
# Fixed: Check for .ok field instead of .status
test_service "wppconnect-bot    " "curl -s http://localhost:3005/health | jq -e '.ok == true'"
test_service "Web UI            " "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000 | grep -q 200"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Monitoring Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

test_service "Dashboard         " "curl -s http://localhost:8080/health | jq -e '.status == \"ok\"'"
# Fixed: Accept both "green" and "yellow" status (yellow is normal for single-node)
test_service "Elasticsearch     " "curl -s http://localhost:9200/_cluster/health | jq -e '.status == \"green\" or .status == \"yellow\"'"
test_service "Kibana            " "curl -s -o /dev/null -w '%{http_code}' http://localhost:5601 | grep -q 302"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  Background Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

test_service "Filebeat          " "docker-compose ps filebeat | grep -q Up"
test_service "Metricbeat        " "docker-compose ps metricbeat | grep -q 'Up '"
test_service "Cron              " "docker-compose ps cron | grep -q Up"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  WhatsApp Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check wppconnect using correct field
wpp_ok=$(curl -s http://localhost:3005/health 2>/dev/null | jq -r '.ok' 2>/dev/null)
wpp_session=$(curl -s http://localhost:3005/health 2>/dev/null | jq -r '.session' 2>/dev/null)

if [ "$wpp_ok" = "true" ]; then
    echo -e "  Connection: ${GREEN}✅ CONNECTED${NC} (Session: $wpp_session)"
    
    # Fetch groups
    echo ""
    echo "  Available Groups:"
    groups=$(curl -s http://localhost:3005/groups 2>/dev/null)
    if echo "$groups" | jq -e '.groups | length > 0' > /dev/null 2>&1; then
        group_count=$(echo "$groups" | jq -r '.groups | length')
        echo "    Found $group_count groups:"
        echo "$groups" | jq -r '.groups[] | "    • \(.name) (\(.participants) members)"'
    else
        echo "    (No groups found)"
    fi
else
    echo -e "  Connection: ${RED}❌ NOT CONNECTED${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  Container Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

docker-compose ps

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Access URLs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Web UI:       http://192.168.1.66:3000"
echo "  Python API:   http://192.168.1.66:5000"
echo "  WhatsApp Bot: http://192.168.1.66:3005"
echo "  Dashboard:    http://192.168.1.66:8080"
echo "  Kibana:       http://192.168.1.66:5601"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6️⃣  Service Health Details"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "  Python API:"
curl -s http://localhost:5000/health 2>/dev/null | jq '.' 2>/dev/null || echo "    Error"

echo ""
echo "  wppconnect-bot:"
curl -s http://localhost:3005/health 2>/dev/null | jq '.' 2>/dev/null || echo "    Error"

echo ""
echo "  Elasticsearch:"
curl -s http://localhost:9200/_cluster/health 2>/dev/null | jq '{status, number_of_nodes, active_shards}' 2>/dev/null || echo "    Error"

echo ""
echo "================================================"
echo "✅ HEALTH CHECK COMPLETE"
echo "================================================"
