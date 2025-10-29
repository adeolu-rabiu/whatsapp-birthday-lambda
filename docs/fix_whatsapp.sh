#!/bin/bash

echo "WhatsApp Connection Diagnostic Tool"
echo "===================================="

# Check if the container is running
echo "Checking WhatsApp bot container..."
CONTAINER_ID=$(docker ps | grep baileys-bot | awk '{print $1}')

if [ -z "$CONTAINER_ID" ]; then
  echo "❌ WhatsApp bot container is not running!"
  echo "Starting the container..."
  docker-compose up -d whatsapp-baileys-bot
  sleep 10
  CONTAINER_ID=$(docker ps | grep baileys-bot | awk '{print $1}')
  if [ -z "$CONTAINER_ID" ]; then
    echo "❌ Failed to start WhatsApp bot container!"
    exit 1
  fi
fi

echo "✅ WhatsApp bot container is running with ID: $CONTAINER_ID"

# Check the container logs
echo "Checking container logs..."
docker logs $CONTAINER_ID --tail 20

# Check the WhatsApp connection status
echo "Checking WhatsApp connection..."
RESPONSE=$(curl -s http://localhost:3005/status)
echo "Status response: $RESPONSE"

# Check available groups
echo "Checking available groups..."
GROUPS=$(curl -s http://localhost:3005/groups)
echo "Groups response: $GROUPS"

# Restart the container if needed
echo "Would you like to restart the WhatsApp bot container? (y/n)"
read -r restart_choice

if [[ "$restart_choice" == "y" || "$restart_choice" == "Y" ]]; then
  echo "Restarting WhatsApp bot container..."
  docker restart $CONTAINER_ID
  sleep 10
  echo "Container restarted. Checking status again..."
  RESPONSE=$(curl -s http://localhost:3005/status)
  echo "Status after restart: $RESPONSE"
fi

echo "Diagnostic complete!"
