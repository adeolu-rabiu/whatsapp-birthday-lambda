#!/bin/bash

# WhatsApp Birthday Bot Service Manager
# Improved version with better error handling and port conflict resolution

# Set error handling
set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the absolute path of the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

function log_warning() {
  echo -e "${YELLOW}⚠️ $1${NC}"
}

function log_error() {
  echo -e "${RED}❌ $1${NC}"
}

function log_info() {
  echo -e "${BLUE}📌 $1${NC}"
}

function ensure_log_files() {
  # Ensure log directories and files exist
  mkdir -p "$PROJECT_ROOT/app/scheduler"
  mkdir -p "$PROJECT_ROOT/app/whatsapp"
  mkdir -p "$PROJECT_ROOT/web-ui/birthday-manager"
  
  # Create log files if they don't exist
  touch "$PROJECT_ROOT/app/scheduler/scheduler.log"
  touch "$PROJECT_ROOT/app/whatsapp/whatsapp.log"
  touch "$PROJECT_ROOT/web-ui/birthday-manager/web-ui.log"
  
  log_success "Log files are ready"
}

function ensure_env_file() {
  if [ ! -f "$PROJECT_ROOT/.env" ]; then
    log_warning ".env file not found! Creating one with default values."
    cat <<EOT > "$PROJECT_ROOT/.env"
REACT_APP_API_URL=https://s9i0mo0564.execute-api.eu-west-2.amazonaws.com/
AWS_REGION=eu-west-2
DYNAMODB_TABLE_NAME=Birthdays
WHATSAPP_GROUPS_TABLE=WhatsAppGroups
WEB_UI_PORT=3000
API_PORT=3001
EOT
    log_success ".env file created. Please review and update it as needed."
  fi
  
  # Export environment variables
  export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs) 2>/dev/null
  log_info "Loaded environment variables from .env"
}

function check_ports() {
  # Check if Web UI port is already in use
  WEB_UI_PORT=${WEB_UI_PORT:-3000}
  if lsof -i:$WEB_UI_PORT > /dev/null 2>&1; then
    NEW_PORT=$((WEB_UI_PORT + 1))
    log_warning "Port $WEB_UI_PORT is already in use. Setting Web UI port to $NEW_PORT"
    WEB_UI_PORT=$NEW_PORT
    # Update .env file
    sed -i "s/WEB_UI_PORT=.*/WEB_UI_PORT=$WEB_UI_PORT/" "$PROJECT_ROOT/.env" 2>/dev/null
  fi
  
  # Check if API port is already in use
  API_PORT=${API_PORT:-3001}
  if lsof -i:$API_PORT > /dev/null 2>&1; then
    NEW_PORT=$((API_PORT + 1))
    log_warning "Port $API_PORT is already in use. Setting API port to $NEW_PORT"
    API_PORT=$NEW_PORT
    # Update .env file
    sed -i "s/API_PORT=.*/API_PORT=$API_PORT/" "$PROJECT_ROOT/.env" 2>/dev/null
  fi
}

function start_scheduler() {
  log_info "Starting Birthday Scheduler..."
  cd "$PROJECT_ROOT"
  
  # Check if already running
  if pgrep -f "python.*birthday_scheduler.py" > /dev/null; then
    log_warning "Birthday Scheduler is already running"
    return
  fi
  
  cd "$PROJECT_ROOT/app/scheduler"
  nohup python3 birthday_scheduler.py > scheduler.log 2>&1 &
  sleep 2
  
  # Verify it started
  if pgrep -f "python.*birthday_scheduler.py" > /dev/null; then
    log_success "Birthday Scheduler started successfully"
  else
    log_error "Failed to start Birthday Scheduler. Check logs for details."
  fi
}

function start_whatsapp_bot() {
  log_info "Starting WhatsApp Bot..."
  cd "$PROJECT_ROOT"
  
  # Check if already running
  if pgrep -f "python.*whatsapp_sender.py" > /dev/null; then
    log_warning "WhatsApp Bot is already running"
    return
  fi
  
  # Create a simple wrapper script if it doesn't exist
  if [ ! -f "$PROJECT_ROOT/app/whatsapp/whatsapp_service.py" ]; then
    cat <<EOT > "$PROJECT_ROOT/app/whatsapp/whatsapp_service.py"
import logging
import time
import os
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("whatsapp.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('whatsapp_service')

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

logger.info("WhatsApp service starting...")

try:
    from whatsapp.whatsapp_sender import WhatsAppSender
    
    # Initialize WhatsApp
    whatsapp = WhatsAppSender()
    logger.info("WhatsApp sender initialized")
    
    # Keep the service running
    while True:
        logger.info("WhatsApp service is running...")
        time.sleep(60)
except Exception as e:
    logger.error(f"Error in WhatsApp service: {str(e)}")
    import traceback
    logger.error(traceback.format_exc())
EOT
  fi
  
  cd "$PROJECT_ROOT/app/whatsapp"
  nohup python3 whatsapp_service.py > whatsapp.log 2>&1 &
  sleep 2
  
  # Verify it started
  if pgrep -f "python.*whatsapp_service.py" > /dev/null; then
    log_success "WhatsApp Bot started successfully"
  else
    log_error "Failed to start WhatsApp Bot. Check logs for details."
  fi
}

function start_api() {
  log_info "Starting API Lambda locally..."
  cd "$PROJECT_ROOT"
  
  # Check if already running
  if pgrep -f "sam.*local start-api" > /dev/null; then
    log_warning "API (Lambda) is already running"
    return
  fi
  
  # Check if SAM CLI is installed
  if ! command -v sam &> /dev/null; then
    log_warning "AWS SAM CLI not found! Skipping local API start."
    log_info "To install SAM CLI: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
    return
  fi
  
  cd "$PROJECT_ROOT/api_lambda"
  nohup sam build && sam local start-api --port $API_PORT > api.log 2>&1 &
  
  sleep 5
  
  # Verify it started
  if pgrep -f "sam.*local start-api" > /dev/null; then
    log_success "API Lambda started successfully at http://127.0.0.1:$API_PORT"
  else
    log_error "Failed to start API Lambda. Check logs for details."
  fi
}

function start_web_ui() {
  log_info "Starting Web UI..."
  cd "$PROJECT_ROOT"
  
  # Check if already running
  if pgrep -f "npm.*start" > /dev/null; then
    log_warning "Web UI is already running"
    return
  fi
  
  # Check if Node.js is installed
  if ! command -v npm &> /dev/null; then
    log_error "Node.js/npm not found! Cannot start Web UI."
    return
  fi
  
  cd "$PROJECT_ROOT/web-ui/birthday-manager"
  
  # Set port for React app
  export PORT=$WEB_UI_PORT
  
  # Install dependencies if node_modules doesn't exist
  if [ ! -d "node_modules" ]; then
    log_info "Installing Web UI dependencies..."
    npm install --legacy-peer-deps
  fi
  
  nohup npm start > web-ui.log 2>&1 &
  sleep 5
  
  # Verify it started
  if pgrep -f "npm.*start" > /dev/null; then
    log_success "Web UI started successfully at http://localhost:$WEB_UI_PORT"
  else
    log_error "Failed to start Web UI. Check logs for details."
  fi
}

function start_services() {
  echo "Starting the WhatsApp Birthday Reminder System..."
  
  # Setup environment
  ensure_env_file
  ensure_log_files
  check_ports
  
  # Start all components
  start_api
  start_scheduler
  start_whatsapp_bot
  start_web_ui
  
  log_success "All services started successfully!"
  log_info "Web UI: http://localhost:$WEB_UI_PORT"
  log_info "API: http://127.0.0.1:$API_PORT"
  log_info "Logs: app/scheduler/scheduler.log | app/whatsapp/whatsapp.log | web-ui/birthday-manager/web-ui.log"
}

function stop_services() {
  echo "Stopping all running services..."

  pkill -f "python.*birthday_scheduler.py" 2>/dev/null && log_success "Stopped Birthday Scheduler" || log_warning "Birthday Scheduler was not running"
  pkill -f "python.*whatsapp_service.py" 2>/dev/null && log_success "Stopped WhatsApp Bot" || log_warning "WhatsApp Bot was not running"
  pkill -f "npm.*start" 2>/dev/null && log_success "Stopped Web UI" || log_warning "Web UI was not running"
  pkill -f "sam.*local start-api" 2>/dev/null && log_success "Stopped API (Lambda)" || log_warning "API (Lambda) was not running"

  log_success "All services stopped successfully!"
}

function restart_services() {
  echo "🔄 Restarting all services..."
  stop_services
  sleep 2
  start_services
}

function check_status() {
  echo "🔍 Checking service status..."
  pgrep -f "python.*birthday_scheduler.py" > /dev/null && log_success "Birthday Scheduler is running" || log_warning "Birthday Scheduler is not running"
  pgrep -f "python.*whatsapp_service.py" > /dev/null && log_success "WhatsApp Bot is running" || log_warning "WhatsApp Bot is not running"
  pgrep -f "npm.*start" > /dev/null && log_success "Web UI is running" || log_warning "Web UI is not running"
  pgrep -f "sam.*local start-api" > /dev/null && log_success "API (Lambda) is running" || log_warning "API (Lambda) is not running"
}

function view_logs() {
  echo "📜 Viewing logs..."
  
  echo -e "${BLUE}--- Scheduler Logs ---${NC}"
  if [ -f "$PROJECT_ROOT/app/scheduler/scheduler.log" ]; then
    tail -n 20 "$PROJECT_ROOT/app/scheduler/scheduler.log"
  else
    log_error "Scheduler log file not found"
  fi
  
  echo -e "${BLUE}--- WhatsApp Bot Logs ---${NC}"
  if [ -f "$PROJECT_ROOT/app/whatsapp/whatsapp.log" ]; then
    tail -n 20 "$PROJECT_ROOT/app/whatsapp/whatsapp.log"
  else
    log_error "WhatsApp log file not found"
  fi
  
  echo -e "${BLUE}--- Web UI Logs ---${NC}"
  if [ -f "$PROJECT_ROOT/web-ui/birthday-manager/web-ui.log" ]; then
    tail -n 20 "$PROJECT_ROOT/web-ui/birthday-manager/web-ui.log"
  else
    log_error "Web UI log file not found"
  fi
  
  echo -e "${BLUE}--- API Logs ---${NC}"
  if [ -f "$PROJECT_ROOT/api_lambda/api.log" ]; then
    tail -n 20 "$PROJECT_ROOT/api_lambda/api.log"
  else
    log_error "API log file not found"
  fi
}

function show_help() {
  echo "📋 WhatsApp Birthday Bot - Help Guide"
  echo ""
  echo "This service manager helps you control the different components of your system:"
  echo ""
  echo "1. Birthday Scheduler - Python service that checks for birthdays and sends notifications"
  echo "2. WhatsApp Bot - Service that interfaces with WhatsApp Web to send messages"
  echo "3. API - AWS Lambda function for managing birthday data (runs locally using SAM)"
  echo "4. Web UI - React frontend for managing birthdays and groups"
  echo ""
  echo "Recommendations for common issues:"
  echo "- Port conflicts: The script will automatically find free ports"
  echo "- Missing log files: The script will create necessary directories and files"
  echo "- Service not starting: Check the logs for specific error messages"
  echo ""
  echo "Project structure overview:"
  echo "- app/scheduler/ - Birthday scheduler service"
  echo "- app/whatsapp/ - WhatsApp integration"
  echo "- app/db/ - Database access layer"
  echo "- api_lambda/ - AWS Lambda functions for API"
  echo "- web-ui/ - React frontend application"
  echo ""
  log_info "Press any key to continue..."
  read -n 1
}

function check_prerequisites() {
  echo "🔍 Checking prerequisites..."
  
  # Check Python
  if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    log_success "Python is installed: $PYTHON_VERSION"
  else
    log_error "Python 3 is not installed or not in PATH"
  fi
  
  # Check Node.js
  if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    log_success "Node.js is installed: $NODE_VERSION"
  else
    log_error "Node.js is not installed or not in PATH"
  fi
  
  # Check AWS SAM CLI
  if command -v sam &> /dev/null; then
    SAM_VERSION=$(sam --version)
    log_success "AWS SAM CLI is installed: $SAM_VERSION"
  else
    log_warning "AWS SAM CLI is not installed (needed for local API testing)"
  fi
  
  # Check AWS CLI
  if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version)
    log_success "AWS CLI is installed: $AWS_VERSION"
  else
    log_warning "AWS CLI is not installed"
  fi
  
  # Check virtual environment
  if [ -d "$PROJECT_ROOT/venv" ]; then
    log_success "Python virtual environment exists"
  else
    log_warning "Python virtual environment not found"
  fi
  
  log_info "Press any key to continue..."
  read -n 1
}

# Main menu
while true; do
  clear
  echo ""
  echo -e "${BLUE}📦 WhatsApp Birthday Bot Service Manager${NC}"
  echo "1) Start All Services"
  echo "2) Stop All Services"
  echo "3) Restart All Services"
  echo "4) Check Service Status"
  echo "5) View Logs"
  echo "6) Check Prerequisites"
  echo "7) Help & Troubleshooting"
  echo "8) Exit"
  read -p "Choose an option [1-8]: " choice

  case $choice in
    1)
      start_services
      ;;
    2)
      stop_services
      ;;
    3)
      restart_services
      ;;
    4)
      check_status
      ;;
    5)
      view_logs
      ;;
    6)
      check_prerequisites
      ;;
    7)
      show_help
      ;;
    8)
      echo -e "${GREEN}Exiting. Bye 👋${NC}"
      exit 0
      ;;
    *)
      log_error "Invalid choice. Please enter a number between 1 and 8."
      ;;
  esac
  
  echo ""
  read -p "Press Enter to continue..." dummy
done
