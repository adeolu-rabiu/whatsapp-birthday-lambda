#!/bin/bash

echo "===== WhatsApp Birthday Service Launcher ====="

# Project paths
PROJECT_ROOT="$HOME/whatsapp-birthday-lambda"
WHATSAPP_DIR="$PROJECT_ROOT/app/whatsapp"
SERVICE_SCRIPT="$WHATSAPP_DIR/whatsapp_birthday_service.py"

# Check for Docker
echo "Checking Docker availability..."
if command -v docker &> /dev/null; then
    echo "Docker command found, checking if daemon is running..."
    if docker info &> /dev/null; then
        echo "Docker daemon is running."
        DOCKER_AVAILABLE=true
    else
        echo "Docker command exists but daemon is not running."
        echo "If using Docker Desktop, please start it from Windows."
        DOCKER_AVAILABLE=false
    fi
else
    echo "Docker command not found. Docker is not installed or not in PATH."
    DOCKER_AVAILABLE=false
fi

# Check if script exists in the expected location
if [ -f "$SERVICE_SCRIPT" ]; then
    echo "Found WhatsApp Birthday Service script at: $SERVICE_SCRIPT"
else
    echo "ERROR: WhatsApp Birthday Service script not found at: $SERVICE_SCRIPT"
    echo "Checking alternative locations..."
    
    # Search for the script
    FOUND_SCRIPT=$(find "$PROJECT_ROOT" -name "whatsapp_birthday_service.py" -type f | head -n 1)
    
    if [ -n "$FOUND_SCRIPT" ]; then
        echo "Found script at alternative location: $FOUND_SCRIPT"
        SERVICE_SCRIPT="$FOUND_SCRIPT"
    else
        echo "ERROR: Could not find whatsapp_birthday_service.py anywhere in the project."
        exit 1
    fi
fi

# If Docker is available, try to start containers
if [ "$DOCKER_AVAILABLE" = true ]; then
    echo "Starting Docker containers..."
    cd "$PROJECT_ROOT"
    
    # Check if docker-compose.yml exists
    if [ -f "docker-compose.yml" ]; then
        echo "Found docker-compose.yml, starting services..."
        docker-compose up -d
        
        echo "Waiting for services to initialize..."
        sleep 10
        
        echo "Container status:"
        docker-compose ps
    else
        echo "WARNING: docker-compose.yml not found in $PROJECT_ROOT"
    fi
else
    echo "Skipping Docker container startup since Docker is not available."
fi

# Run the birthday service script
echo "Running WhatsApp Birthday Service..."
cd "$(dirname "$SERVICE_SCRIPT")"
SCRIPT_DIR=$(pwd)
echo "Working directory: $SCRIPT_DIR"

# Check if we have a Python virtual environment
if [ -d "$PROJECT_ROOT/venv" ]; then
    echo "Activating Python virtual environment..."
    source "$PROJECT_ROOT/venv/bin/activate"
    
    # Run the birthday service with today's date
    echo "Sending today's birthday messages..."
    TODAY=$(date +"%m-%d")
    echo "Today's date: $TODAY"
    
    # Run the script
    python "$(basename "$SERVICE_SCRIPT")" --force-date $TODAY
    
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        echo "Birthday service execution completed successfully!"
    else
        echo "Birthday service execution failed with exit code: $RESULT"
    fi
else
    echo "WARNING: Python virtual environment not found at $PROJECT_ROOT/venv"
    echo "Trying to run the script with system Python..."
    python "$(basename "$SERVICE_SCRIPT")" --force-date $(date +"%m-%d")
fi

echo "===== Service execution complete ====="
