#!/bin/bash

echo "Starting WhatsApp Birthday Service..."

# Make sure Docker is running
if ! systemctl is-active --quiet docker; then
  echo "Docker is not running, starting it..."
  sudo systemctl start docker
  sleep 5
fi

# Navigate to project directory
cd ~/whatsapp-birthday-lambda

# Check if docker-compose.yml exists
if [ ! -f docker-compose.yml ]; then
  echo "Error: docker-compose.yml not found in $(pwd)"
  echo "Please make sure you're in the correct directory"
  exit 1
fi

# Start the services with docker-compose
echo "Starting containers with docker-compose..."
docker-compose up -d

echo "Checking container status..."
docker-compose ps

# Wait a bit for services to fully start
echo "Waiting for services to initialize..."
sleep 10

# Check if we have a Python virtual environment
if [ -d "venv" ]; then
  echo "Activating Python virtual environment..."
  source venv/bin/activate
  
  # Run the birthday service with today's date
  echo "Sending today's birthday messages..."
  python whatsapp_birthday_service.py --force-date $(date +"%m-%d")
  
  # Or with a specific date (uncomment to use)
  # python whatsapp_birthday_service.py --force-date 04-15
  
  echo "Birthday service execution complete!"
else
  echo "Warning: Python virtual environment not found in $(pwd)/venv"
  echo "Trying to run the script directly..."
  python whatsapp_birthday_service.py --force-date $(date +"%m-%d")
fi

echo "Done!"
