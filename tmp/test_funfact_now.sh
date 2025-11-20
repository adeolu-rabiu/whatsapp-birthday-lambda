#!/bin/bash

cd /opt/whatsapp-birthday-lambda

echo "═══════════════════════════════════════════════════════════"
echo "  Test New Fun Facts Immediately"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check if python-api is running
if ! docker-compose ps python-api | grep -q "Up"; then
    echo "❌ Python API container is not running!"
    echo "   Start it with: docker-compose up -d python-api"
    exit 1
fi

echo "1️⃣ Fetching a random fun fact from the API..."
echo ""

# Try different possible endpoints
ENDPOINTS=(
    "/api/funfact"
    "/funfact"
    "/api/v1/funfact"
    "/get-funfact"
    "/random-fact"
)

for endpoint in "${ENDPOINTS[@]}"; do
    echo "Trying: http://localhost:5000$endpoint"
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" http://localhost:5000$endpoint 2>/dev/null)
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Success!"
        echo ""
        echo "Response:"
        echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
        echo ""
        break
    else
        echo "   Status: $HTTP_CODE"
    fi
done

echo ""
echo "2️⃣ Checking Python API logs for fun fact loading..."
echo ""
docker-compose logs python-api | tail -50 | grep -i "fun\|fact\|load\|init" || echo "No relevant logs found"

echo ""
echo "3️⃣ Checking cron job logs..."
echo ""
docker-compose logs cron | tail -30

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Manual Test Options"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "To manually trigger fun fact send, try:"
echo "1. Check if there's a Lambda function handler:"
echo "   docker-compose exec python-api python -c 'import server; print(dir(server))'"
echo ""
echo "2. Or directly call the Python script:"
echo "   docker-compose exec cron python /app/funfact_sender.py"
echo ""
echo "3. Or check what's in the container:"
echo "   docker-compose exec python-api ls -la /app/"
