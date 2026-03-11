#!/bin/bash

LOG_FILE="/opt/whatsapp-birthday-lambda/logs/birthday_service_runner.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Log start time
log_message "============================================"
log_message "Starting WhatsApp Birthday Service"
# Set AWS credentials environment variables
export AWS_SHARED_CREDENTIALS_FILE="/opt/whatsapp-birthday-lambda/.aws/credentials"
log_message "============================================"

# Change to the project directory
cd /opt/whatsapp-birthday-lambda || {
    log_message "ERROR: Could not change to project directory"
    exit 1
}

# Check WhatsApp connection status
log_message "Checking WhatsApp connection..."
WHATSAPP_STATUS=$(curl -s http://localhost:3005/status)
CONNECTED=$(echo "$WHATSAPP_STATUS" | grep -c "connected\":true")

if [ "$CONNECTED" -eq 0 ]; then
    log_message "⚠️ WhatsApp connection not ready. Attempting to restart the bot..."
    docker restart wppconnect-bot
    # Wait for it to restart
    sleep 20
    # Check again
    WHATSAPP_STATUS=$(curl -s http://localhost:3005/status)
    CONNECTED=$(echo "$WHATSAPP_STATUS" | grep -c "connected\":true")
    
    if [ "$CONNECTED" -eq 0 ]; then
        log_message "❌ WhatsApp still not connected after restart. Aborting."
        exit 1
    else
        log_message "✅ WhatsApp reconnected successfully!"
    fi
else
    log_message "✅ WhatsApp connection is ready: $WHATSAPP_STATUS"
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    log_message "❌ Virtual environment not found. Aborting."
    exit 1
fi

# Activate the virtual environment
log_message "Activating virtual environment..."
source venv/bin/activate || {
    log_message "❌ Failed to activate virtual environment"
    exit 1
}

# Check if the Python script exists
if [ ! -f "app/whatsapp/whatsapp_birthday_service.py" ]; then
    log_message "❌ Birthday service script not found at app/whatsapp/whatsapp_birthday_service.py"
    exit 1
fi

# Run the birthday service with full debug output
log_message "Running birthday service..."
python3 app/whatsapp/whatsapp_birthday_service.py 2>&1 | tee -a "$LOG_FILE"

# Check if the script ran successfully
if [ $? -ne 0 ]; then
    log_message "❌ Birthday service failed with error code $?"
else
    log_message "✅ Birthday service completed"
fi

# Deactivate the virtual environment
deactivate

# Log completion
log_message "============================================"
log_message "Completed WhatsApp Birthday Service"
log_message "============================================"
