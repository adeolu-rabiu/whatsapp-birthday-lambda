#!/bin/bash

cd /opt/whatsapp-birthday-lambda

# Update LOG_DIR in the script
sed -i 's|LOG_DIR = "/opt/whatsapp-birthday-lambda/logs"|LOG_DIR = "/app/logs"|g' app/whatsapp/whatsapp_birthday_service.py

echo "✅ Updated LOG_DIR to /app/logs"

# Verify the change
grep "LOG_DIR" app/whatsapp/whatsapp_birthday_service.py
