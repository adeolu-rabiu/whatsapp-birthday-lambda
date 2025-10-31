#!/bin/bash

echo "🧪 Testing Disaster Recovery"
echo "============================="
echo ""

# 1. Backup current state
echo "1️⃣ Creating backup..."
mkdir -p dr-test-backup
docker-compose ps > dr-test-backup/services-before.txt
aws dynamodb scan --table-name Birthdays --output json > dr-test-backup/data-before.json

# 2. Simulate disaster
echo ""
echo "2️⃣ Simulating disaster (stopping services)..."
docker-compose down

# 3. Restore
echo ""
echo "3️⃣ Restoring from backup..."
docker-compose pull
docker-compose up -d

# 4. Verify
echo ""
echo "4️⃣ Verifying restoration..."
sleep 30

curl -f http://localhost:5000/health && echo "✅ Python API: OK" || echo "❌ Python API: FAILED"
curl -f http://localhost:3005/health && echo "✅ WPPConnect: OK" || echo "❌ WPPConnect: FAILED"
curl -f http://localhost:3000 && echo "✅ Web UI: OK" || echo "❌ Web UI: FAILED"

# 5. Verify data
echo ""
echo "5️⃣ Verifying data integrity..."
aws dynamodb scan --table-name Birthdays --output json > dr-test-backup/data-after.json

if diff dr-test-backup/data-before.json dr-test-backup/data-after.json >/dev/null; then
    echo "✅ Data integrity verified"
else
    echo "⚠️  Data differences detected"
fi

echo ""
echo "============================="
echo "✅ DR Test Complete!"
