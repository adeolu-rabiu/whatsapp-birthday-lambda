#!/bin/bash

echo "Stopping all running services..."

# Stop Birthday Scheduler
pkill -f birthday_scheduler.py && echo "✅ Stopped Birthday Scheduler" || echo "⚠️ Birthday Scheduler was not running"

# Stop WhatsApp Bot
pkill -f whatsapp_sender.py && echo "✅ Stopped WhatsApp Bot" || echo "⚠️ WhatsApp Bot was not running"

# Stop React Frontend
pkill -f npm && echo "✅ Stopped Web UI" || echo "⚠️ Web UI was not running"

# Stop API (Lambda)
pkill -f sam && echo "✅ Stopped API (Lambda)" || echo "⚠️ API (Lambda) was not running"

echo "✅ All services stopped successfully!"
exit 0

