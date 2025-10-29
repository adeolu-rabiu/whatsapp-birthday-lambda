#!/bin/bash

cd /opt/whatsapp-birthday-lambda

echo "🔧 Adding Cron to Docker Compose"
echo "================================="
echo ""

# Check if cron service exists in docker-compose.yml
if grep -q "^  cron:" docker-compose.yml; then
    echo "Cron service found in docker-compose.yml"
    
    # Stop and remove standalone cron
    docker stop whatsapp-birthday-lambda_cron 2>/dev/null
    docker rm whatsapp-birthday-lambda_cron 2>/dev/null
    
    # Start cron via docker-compose
    docker-compose up -d cron
    
    sleep 5
    
    echo ""
    echo "Cron status:"
    docker-compose ps cron
    
    echo ""
    echo "Verify crontab:"
    docker exec whatsapp-birthday-lambda_cron crontab -l
else
    echo "❌ Cron service not found in docker-compose.yml"
    echo "Keeping standalone container"
fi

echo ""
echo "✅ Cron update complete"
