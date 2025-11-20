#!/bin/bash

cd /opt/whatsapp-birthday-lambda

echo "☢️  NUCLEAR OPTION - Complete Clean & Rebuild"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "⚠️  WARNING: This will:"
echo "   - Stop ALL containers"
echo "   - Remove ALL containers"
echo "   - Remove ALL Docker images for this project"
echo "   - Clear ALL Docker build cache"
echo "   - Rebuild everything from scratch"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "1️⃣ Stopping all containers..."
docker-compose down

echo ""
echo "2️⃣ Removing all project images..."
docker images | grep whatsapp-birthday-lambda | awk '{print $3}' | xargs -r docker rmi -f

echo ""
echo "3️⃣ Removing all unused images..."
docker image prune -a -f

echo ""
echo "4️⃣ Removing build cache..."
docker builder prune -a -f

echo ""
echo "5️⃣ Cleaning Python cache..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true

echo ""
echo "6️⃣ Rebuilding all containers..."
docker-compose build --no-cache --pull

echo ""
echo "7️⃣ Starting services..."
docker-compose up -d

echo ""
echo "8️⃣ Waiting for services to start..."
sleep 10

echo ""
echo "9️⃣ Status check..."
docker-compose ps

echo ""
echo "✅ Nuclear clean complete!"
echo ""
echo "Check logs: docker-compose logs -f"
