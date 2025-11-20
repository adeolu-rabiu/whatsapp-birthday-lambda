#!/bin/bash

cd /opt/whatsapp-birthday-lambda

echo "═══════════════════════════════════════════════════════════"
echo "  DEEP CLEAN - Force Bot to Use New Fun Facts"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Step 1: Stop all relevant containers
echo "1️⃣ Stopping containers..."
docker-compose stop python-api cron wppconnect-bot
echo ""

# Step 2: Remove containers completely
echo "2️⃣ Removing containers (to clear any cached data)..."
docker-compose rm -f python-api cron wppconnect-bot
echo ""

# Step 3: Check where fun facts are stored
echo "3️⃣ Looking for fun facts files..."
echo ""
echo "Searching for fun fact data files:"
find . -type f \( -name "*funfact*" -o -name "*fun_fact*" -o -name "*quotes*" -o -name "*facts*" \) 2>/dev/null | grep -v node_modules | grep -v ".git"
echo ""

# Step 4: Clean Python cache
echo "4️⃣ Cleaning Python cache..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
find . -type f -name "*.pyo" -delete 2>/dev/null || true
echo "✅ Python cache cleaned"
echo ""

# Step 5: Clean Docker build cache
echo "5️⃣ Cleaning Docker build cache..."
docker builder prune -f
echo ""

# Step 6: Check for .env file
echo "6️⃣ Checking environment configuration..."
if [ -f .env ]; then
    echo "Found .env file. Checking for fun fact related variables:"
    grep -i "fun\|fact\|quote" .env || echo "No fun fact variables found in .env"
else
    echo "⚠️ No .env file found"
fi
echo ""

# Step 7: Rebuild containers from scratch
echo "7️⃣ Rebuilding containers from scratch (no cache)..."
echo ""
docker-compose build --no-cache python-api cron
echo ""

# Step 8: Restart services
echo "8️⃣ Starting services with fresh containers..."
docker-compose up -d python-api
sleep 5
docker-compose up -d cron
sleep 3
docker-compose up -d wppconnect-bot
echo ""

# Step 9: Verify
echo "9️⃣ Verification..."
echo ""
echo "Container status:"
docker-compose ps python-api cron wppconnect-bot
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "  Next Steps"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "1. Check the logs to ensure new fun facts are loaded:"
echo "   docker-compose logs python-api | grep -i 'fun\|fact'"
echo ""
echo "2. Check cron job logs:"
echo "   docker-compose logs cron"
echo ""
echo "3. Trigger a manual fun fact send to test:"
echo "   curl -X POST http://localhost:5000/send-funfact"
echo ""
echo "✅ Deep clean complete!"
