#!/bin/bash

set -e  # Exit on error

echo "================================================"
echo "🧹 COMPLETE DOCKER CLEANUP AND REBUILD"
echo "================================================"
echo ""

# ================================================
# STEP 1: Stop All Services
# ================================================
echo "1️⃣ Stopping all services..."
docker-compose down -v --remove-orphans
echo "✅ Services stopped"
echo ""

# ================================================
# STEP 2: Remove All Containers
# ================================================
echo "2️⃣ Removing all containers..."
docker rm -f $(docker ps -aq) 2>/dev/null || echo "No containers to remove"
echo "✅ Containers removed"
echo ""

# ================================================
# STEP 3: Remove All Images
# ================================================
echo "3️⃣ Removing all Docker images..."
docker rmi -f $(docker images -q) 2>/dev/null || echo "No images to remove"
echo "✅ Images removed"
echo ""

# ================================================
# STEP 4: Remove All Volumes
# ================================================
echo "4️⃣ Removing all volumes..."
docker volume rm $(docker volume ls -q) 2>/dev/null || echo "No volumes to remove"
echo "✅ Volumes removed"
echo ""

# ================================================
# STEP 5: Remove All Networks
# ================================================
echo "5️⃣ Removing all networks..."
docker network prune -f
echo "✅ Networks cleaned"
echo ""

# ================================================
# STEP 6: Complete System Prune
# ================================================
echo "6️⃣ Running complete system prune..."
docker system prune -af --volumes
echo "✅ System pruned"
echo ""

# ================================================
# STEP 7: Show Cleanup Results
# ================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Cleanup Complete - Current State:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Containers: $(docker ps -a | wc -l)"
echo "Images: $(docker images | wc -l)"
echo "Volumes: $(docker volume ls | wc -l)"
echo "Networks: $(docker network ls | wc -l)"
echo ""

# ================================================
# STEP 8: Build All Images
# ================================================
echo "================================================"
echo "🔨 BUILDING ALL IMAGES"
echo "================================================"
echo ""

services=(
    "python-api"
    "wppconnect-bot"
    "web-ui"
    "dashboard"
    "filebeat"
    "cron"
)

for service in "${services[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔨 Building: $service"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    docker-compose build --no-cache $service
    echo "✅ $service built successfully"
    echo ""
done

echo "✅ All images built successfully!"
echo ""

# ================================================
# STEP 9: Show Built Images
# ================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Built Images:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker images | grep -E "whatsapp-birthday-lambda|REPOSITORY"
echo ""

echo "================================================"
echo "✅ REBUILD COMPLETE!"
echo "================================================"
echo ""
echo "Next step: Run './start-and-test.sh' to start all services"
