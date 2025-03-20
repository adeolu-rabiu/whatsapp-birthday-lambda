#!/bin/bash

# Set error handling
set -e

echo "Starting the WhatsApp Birthday Reminder System..."

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    echo "Loaded environment variables from .env"
else
    echo "⚠️  .env file not found! Ensure it's properly set up."
    exit 1
fi

# Start API (Lambda) using AWS SAM CLI
echo "Starting API Lambda locally..."
cd api_lambda
sam build && sam local start-api &

# Wait for API to be ready
sleep 5
echo "API started at http://127.0.0.1:3000"

# Start Birthday Scheduler
echo "Starting Birthday Scheduler..."
cd ../app/scheduler
nohup python3 birthday_scheduler.py > scheduler.log 2>&1 &

# Start WhatsApp Bot
echo "Starting WhatsApp Bot..."
cd ../whatsapp
nohup python3 whatsapp_sender.py > whatsapp.log 2>&1 &

# Start Frontend (React)
echo "Starting Web UI..."
cd ../../web-ui
npm install
nohup npm start > web-ui.log 2>&1 &

echo "✅ All services started successfully!"
echo "📌 Web UI: http://localhost:3000"
echo "📌 API: http://127.0.0.1:3000"
echo "📌 Logs: scheduler.log | whatsapp.log | web-ui.log"

exit 0

