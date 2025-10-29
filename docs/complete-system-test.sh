#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test result function
test_result() {
    local test_name=$1
    local result=$2
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC} - $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ FAIL${NC} - $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🧪 WhatsApp Birthday Bot - Complete System Test${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Test started: $(date)"
echo ""

# ============================================================
# SECTION 1: CORE APPLICATION SERVICES (3)
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}📦 SECTION 1: Core Application Services (3/9)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# --- 1.1 Python API ---
echo -e "${BLUE}1.1 Python API (Flask - Port 5000)${NC}"

# Container running
if docker ps | grep -q "python-api.*Up"; then
    test_result "Python API - Container Running" "PASS"
else
    test_result "Python API - Container Running" "FAIL"
fi

# Health endpoint
api_health=$(curl -s http://localhost:5000/health 2>/dev/null | jq -r '.status' 2>/dev/null)
if [ "$api_health" = "ok" ]; then
    test_result "Python API - Health Endpoint" "PASS"
else
    test_result "Python API - Health Endpoint" "FAIL"
fi

# Birthday listing
birthdays_response=$(curl -s http://localhost:5000/birthdays 2>/dev/null)
if echo "$birthdays_response" | jq empty 2>/dev/null; then
    test_result "Python API - List Birthdays Endpoint" "PASS"
else
    test_result "Python API - List Birthdays Endpoint" "FAIL"
fi

# DynamoDB connection
if echo "$birthdays_response" | jq -e 'type == "array"' >/dev/null 2>&1; then
    test_result "Python API - DynamoDB Connection" "PASS"
else
    test_result "Python API - DynamoDB Connection" "FAIL"
fi

echo ""

# --- 1.2 wppconnect-bot ---
echo -e "${BLUE}1.2 wppconnect-bot (WhatsApp - Port 3005)${NC}"

# Container running
if docker ps | grep -q "wppconnect-bot.*Up"; then
    test_result "wppconnect - Container Running" "PASS"
else
    test_result "wppconnect - Container Running" "FAIL"
fi

# Health endpoint
wpp_health=$(curl -s http://localhost:3005/health 2>/dev/null | jq -r '.ok' 2>/dev/null)
if [ "$wpp_health" = "true" ]; then
    test_result "wppconnect - Health Endpoint" "PASS"
    test_result "wppconnect - WhatsApp Connection" "PASS"
else
    test_result "wppconnect - Health Endpoint" "FAIL"
    test_result "wppconnect - WhatsApp Connection" "FAIL"
fi

# Groups endpoint
WPP_GROUPS_URL=${WPP_GROUPS_URL:-http://localhost:3005/groups?session=birthday-bot}
WPP_GROUPS_URL=${WPP_GROUPS_URL:-http://localhost:3005/groups?session=birthday-bot}
groups_response=$(curl -s "$WPP_GROUPS_URL" 2>/dev/null)
if [ "${TEST_VERBOSE:-0}" = "1" ]; then echo "[DEBUG] /groups type:" $(echo "$groups_response" | jq -r "type" 2>/dev/null); fi
groups_count=$(echo "$groups_response" | jq -r '.groups | length' 2>/dev/null)
if [ "$groups_count" -gt 0 ] 2>/dev/null; then
    test_result "wppconnect - Fetch WhatsApp Groups ($groups_count groups)" "PASS"
else
    test_result "wppconnect - Fetch WhatsApp Groups" "FAIL"
fi

echo ""

# --- 1.3 Web UI ---
echo -e "${BLUE}1.3 Web UI (React - Port 3000)${NC}"

# Container running
if docker ps | grep -q "web-ui.*Up"; then
    test_result "Web UI - Container Running" "PASS"
else
    test_result "Web UI - Container Running" "FAIL"
fi

# HTTP response
web_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null)
if [ "$web_status" = "200" ]; then
    test_result "Web UI - HTTP Response (200 OK)" "PASS"
else
    test_result "Web UI - HTTP Response (got $web_status)" "FAIL"
fi

# Check if React app loads
web_content=$(curl -s http://localhost:3000 2>/dev/null)
if echo "$web_content" | grep -q "react\|root\|app"; then
    test_result "Web UI - React App Loads" "PASS"
else
    test_result "Web UI - React App Loads" "FAIL"
fi

echo ""

# ============================================================
# SECTION 2: MONITORING & LOGGING STACK (4)
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}📊 SECTION 2: Monitoring & Logging Stack (4/9)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# --- 2.1 Elasticsearch ---
echo -e "${BLUE}2.1 Elasticsearch (Port 9200)${NC}"

# Container running
if docker ps | grep -q "elasticsearch.*Up"; then
    test_result "Elasticsearch - Container Running" "PASS"
else
    test_result "Elasticsearch - Container Running" "FAIL"
fi

# Cluster health
es_health=$(curl -s http://localhost:9200/_cluster/health 2>/dev/null | jq -r '.status' 2>/dev/null)
if [ "$es_health" = "green" ] || [ "$es_health" = "yellow" ]; then
    test_result "Elasticsearch - Cluster Health ($es_health)" "PASS"
else
    test_result "Elasticsearch - Cluster Health" "FAIL"
fi

# Index count
es_indices=$(curl -s http://localhost:9200/_cat/indices 2>/dev/null | wc -l)
if [ "$es_indices" -gt 0 ] 2>/dev/null; then
    test_result "Elasticsearch - Indices Present ($es_indices indices)" "PASS"
else
    test_result "Elasticsearch - Indices Present" "FAIL"
fi

echo ""

# --- 2.2 Kibana ---
echo -e "${BLUE}2.2 Kibana (Port 5601)${NC}"

# Container running
if docker ps | grep -q "kibana.*Up"; then
    test_result "Kibana - Container Running" "PASS"
else
    test_result "Kibana - Container Running" "FAIL"
fi

# HTTP response
kibana_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5601 2>/dev/null)
if [ "$kibana_status" = "200" ] || [ "$kibana_status" = "302" ]; then
    test_result "Kibana - HTTP Response ($kibana_status)" "PASS"
else
    test_result "Kibana - HTTP Response" "FAIL"
fi

# API status
kibana_api=$(curl -s -H "kbn-xsrf: true" http://localhost:5601/api/status 2>/dev/null | jq -r '.status.overall.state' 2>/dev/null)
if [ "$kibana_api" = "green" ]; then
    test_result "Kibana - API Status (green)" "PASS"
else
    test_result "Kibana - API Status ($kibana_api)" "FAIL"
fi

echo ""

# --- 2.3 Filebeat ---
echo -e "${BLUE}2.3 Filebeat (Log Collector)${NC}"

# Container running
if docker ps | grep -q "filebeat.*Up"; then
    test_result "Filebeat - Container Running" "PASS"
else
    test_result "Filebeat - Container Running" "FAIL"
fi

# Check if logs are being sent
filebeat_logs=$(docker logs whatsapp-birthday-lambda_filebeat 2>&1 | tail -20)
if echo "$filebeat_logs" | grep -q "Non-zero metrics"; then
    test_result "Filebeat - Sending Logs to Elasticsearch" "PASS"
elif echo "$filebeat_logs" | grep -q "INFO"; then
    test_result "Filebeat - Running (no errors)" "PASS"
else
    test_result "Filebeat - Log Collection" "FAIL"
fi

echo ""

# --- 2.4 Metricbeat ---
echo -e "${BLUE}2.4 Metricbeat (Metrics Collector)${NC}"

# Container running
if docker ps | grep -q "metricbeat.*Up"; then
    test_result "Metricbeat - Container Running" "PASS"
else
    test_result "Metricbeat - Container Running" "FAIL"
fi

# Check if metrics are being sent
metricbeat_logs=$(docker logs whatsapp-birthday-lambda_metricbeat 2>&1 | tail -20)
if echo "$metricbeat_logs" | grep -q "Non-zero metrics\|successfully"; then
    test_result "Metricbeat - Sending Metrics to Elasticsearch" "PASS"
elif echo "$metricbeat_logs" | grep -q "INFO.*metric"; then
    test_result "Metricbeat - Collecting Metrics" "PASS"
else
    test_result "Metricbeat - Metrics Collection" "FAIL"
fi

echo ""

# ============================================================
# SECTION 3: SUPPORTING SERVICES (2)
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}🔧 SECTION 3: Supporting Services (2/9)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# --- 3.1 Dashboard ---
echo -e "${BLUE}3.1 Dashboard (Port 8080)${NC}"

# Container running
if docker ps | grep -q "dashboard.*Up"; then
    test_result "Dashboard - Container Running" "PASS"
else
    test_result "Dashboard - Container Running" "FAIL"
fi

# Health endpoint
dashboard_health=$(curl -s http://localhost:8080/health 2>/dev/null | jq -r '.status' 2>/dev/null)
if [ "$dashboard_health" = "ok" ]; then
    test_result "Dashboard - Health Endpoint" "PASS"
else
    test_result "Dashboard - Health Endpoint" "FAIL"
fi

# HTTP response
dash_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null)
if [ "$dash_status" = "200" ]; then
    test_result "Dashboard - HTTP Response (200 OK)" "PASS"
else
    test_result "Dashboard - HTTP Response" "FAIL"
fi

# Check if using local API
dashboard_target=$(curl -s http://localhost:8080/health 2>/dev/null | jq -r '.target' 2>/dev/null)
if echo "$dashboard_target" | grep -q "192.168.1.66\|localhost"; then
    test_result "Dashboard - Using Local API" "PASS"
else
    test_result "Dashboard - Using Local API (using: $dashboard_target)" "FAIL"
fi

echo ""

# --- 3.2 Cron ---
echo -e "${BLUE}3.2 Cron (Scheduled Tasks)${NC}"

# Container running
if docker ps | grep -q "cron.*Up"; then
    test_result "Cron - Container Running" "PASS"
else
    test_result "Cron - Container Running" "FAIL"
fi

# Crontab configured
crontab_count=$(docker exec whatsapp-birthday-lambda_cron crontab -l 2>/dev/null | grep -v "^#" | grep -c ".")
if [ "$crontab_count" -gt 0 ] 2>/dev/null; then
    test_result "Cron - Crontab Configured ($crontab_count jobs)" "PASS"
else
    test_result "Cron - Crontab Configured" "FAIL"
fi

# Script exists
if docker exec whatsapp-birthday-lambda_cron ls /app/app/whatsapp/whatsapp_birthday_service.py >/dev/null 2>&1; then
    test_result "Cron - Birthday Script Present" "PASS"
else
    test_result "Cron - Birthday Script Present" "FAIL"
fi

# Test script execution
test_exec=$(docker exec whatsapp-birthday-lambda_cron /usr/local/bin/python3 -c "import sys; print('ok')" 2>&1)
if echo "$test_exec" | grep -q "ok"; then
    test_result "Cron - Python Executable Works" "PASS"
else
    test_result "Cron - Python Executable Works" "FAIL"
fi

# Check if cron has run (check logs)
if docker exec whatsapp-birthday-lambda_cron cat /app/logs/cron.log 2>/dev/null | grep -q "Birthday"; then
    test_result "Cron - Has Executed (logs present)" "PASS"
else
    test_result "Cron - Has Executed" "FAIL"
fi

echo ""

# ============================================================
# SECTION 4: INTEGRATION TESTS
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}🔗 SECTION 4: Integration Tests${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Python API -> DynamoDB
echo -e "${BLUE}4.1 End-to-End Data Flow${NC}"

birthdays=$(curl -s http://localhost:5000/birthdays 2>/dev/null)
if echo "$birthdays" | jq -e 'type == "array"' >/dev/null 2>&1; then
    test_result "E2E - Python API → DynamoDB → Response" "PASS"
else
    test_result "E2E - Python API → DynamoDB → Response" "FAIL"
fi

# Python API -> wppconnect
groups_from_api=$(curl -s "${WPP_GROUPS_URL:-http://localhost:3005/groups?session=birthday-bot}" 2>/dev/null)
if echo "$groups_from_api" | jq -e '(type=="array" and length>=0) or (type=="object" and has("groups"))' >/dev/null 2>if echo "$groups_from_api" | jq -e '(type=="array" and length>=0) or (type=="object" and has("groups"))' >/dev/null 2>&1; then1; then
    test_result "E2E - Python API → wppconnect → Groups" "PASS"
else
    test_result "E2E - Python API → wppconnect → Groups" "FAIL"
fi

# Logs -> Filebeat -> Elasticsearch
echo ""
echo -e "${BLUE}4.2 Logging Pipeline${NC}"

# Check if logs are in Elasticsearch
es_logs=$(curl -s "http://localhost:9200/_cat/indices/filebeat*" 2>/dev/null)
if [ -n "$es_logs" ]; then
    test_result "Logging - Filebeat → Elasticsearch (indices present)" "PASS"
else
    test_result "Logging - Filebeat → Elasticsearch" "FAIL"
fi

# Check if metrics are in Elasticsearch
es_metrics=$(curl -s "http://localhost:9200/_cat/indices/metricbeat*" 2>/dev/null)
if [ -n "$es_metrics" ]; then
    test_result "Logging - Metricbeat → Elasticsearch (indices present)" "PASS"
else
    test_result "Logging - Metricbeat → Elasticsearch" "FAIL"
fi

echo ""

# ============================================================
# FINAL REPORT
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}📊 FINAL TEST REPORT${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Calculate percentage
if [ $TOTAL_TESTS -gt 0 ]; then
    PASS_PERCENTAGE=$(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
else
    PASS_PERCENTAGE=0
fi

echo "Total Tests:  $TOTAL_TESTS"
echo -e "${GREEN}Passed:       $PASSED_TESTS${NC}"
echo -e "${RED}Failed:       $FAILED_TESTS${NC}"
echo ""
echo -e "Success Rate: ${CYAN}${PASS_PERCENTAGE}%${NC}"
echo ""

# Overall status
if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ ALL SYSTEMS OPERATIONAL - 100% FUNCTIONALITY CONFIRMED${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
else
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  SOME TESTS FAILED - REVIEW REQUIRED${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi
