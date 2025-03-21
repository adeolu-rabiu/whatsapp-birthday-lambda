#!/bin/bash

# Set error handling
set -e

function start_services() {
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
  cd ../../web-ui/birthday-manager
  npm install
  nohup npm start > web-ui.log 2>&1 &

  echo "✅ All services started successfully!"
  echo "📌 Web UI: http://localhost:3000"
  echo "📌 API: http://127.0.0.1:3000"
  echo "📌 Logs: scheduler.log | whatsapp.log | web-ui.log"
}

function stop_services() {
  echo "Stopping all running services..."

  pkill -f birthday_scheduler.py && echo "✅ Stopped Birthday Scheduler" || echo "⚠️ Birthday Scheduler was not running"
  pkill -f whatsapp_sender.py && echo "✅ Stopped WhatsApp Bot" || echo "⚠️ WhatsApp Bot was not running"
  pkill -f npm && echo "✅ Stopped Web UI" || echo "⚠️ Web UI was not running"
  pkill -f sam && echo "✅ Stopped API (Lambda)" || echo "⚠️ API (Lambda) was not running"

  echo "✅ All services stopped successfully!"
}

while true; do
  echo ""
  echo "📦 WhatsApp Birthday Bot Service Manager"
  echo "1) Start All Services"
  echo "2) Stop All Services"
  echo "3) Exit"
  read -p "Choose an option [1-3]: " choice

  case $choice in
    1)
      start_services
      ;;
    2)
      stop_services
      ;;
    3)
      echo "Exiting. Bye 👋"
      exit 0
      ;;
    *)
      echo "❌ Invalid choice. Please enter 1, 2, or 3."
      ;;
  esac

done

