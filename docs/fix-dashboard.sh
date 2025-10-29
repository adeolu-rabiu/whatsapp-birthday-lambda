#!/bin/bash

cd /opt/whatsapp-birthday-lambda

echo "🔧 Fixing Dashboard Configuration"
echo "=================================="
echo ""

# Update server.py to use Docker service names
sed -i 's|http://localhost:5000|http://python-api:5000|g' dashboard/server.py
sed -i 's|http://localhost:3005|http://wppconnect-bot:3005|g' dashboard/server.py
sed -i 's|http://127.0.0.1:5000|http://python-api:5000|g' dashboard/server.py
sed -i 's|http://127.0.0.1:3005|http://wppconnect-bot:3005|g' dashboard/server.py

echo "✅ Dashboard configuration updated"

# Rebuild and restart dashboard
echo ""
echo "Rebuilding dashboard..."
docker-compose build dashboard
docker-compose restart dashboard

sleep 5

echo ""
echo "Dashboard status:"
docker ps | grep dashboard

echo ""
echo "Testing dashboard health:"
curl -s http://localhost:8080/health | jq . 2>/dev/null || curl -s http://localhost:8080/health

echo ""
echo "✅ Dashboard fix complete"
