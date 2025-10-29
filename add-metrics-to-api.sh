#!/bin/bash

echo "�� Adding Prometheus Metrics to Python API"
echo "==========================================="
echo ""

# 1. Add prometheus_client to requirements
echo "1️⃣ Adding prometheus_client dependency..."
grep -q "prometheus_client" requirements.txt || echo "prometheus_client==0.19.0" >> requirements.txt

# 2. Create metrics module
echo ""
echo "2️⃣ Creating metrics module..."
cat > app/metrics.py << 'PYTHON'
from prometheus_client import Counter, Gauge, Histogram, generate_latest, CONTENT_TYPE_LATEST
from flask import Response
import time

# Message delivery metrics
messages_sent_total = Counter(
    'whatsapp_messages_sent_total',
    'Total WhatsApp messages sent',
    ['group', 'message_type']
)

messages_failed_total = Counter(
    'whatsapp_messages_failed_total',
    'Total WhatsApp messages that failed',
    ['group', 'reason']
)

last_successful_run = Gauge(
    'birthday_bot_last_successful_run_timestamp',
    'Timestamp of last successful birthday check run'
)

daily_check_status = Gauge(
    'birthday_bot_daily_check_status',
    'Status of daily birthday check (1=success, 0=failure)'
)

birthdays_today = Gauge(
    'birthdays_found_today',
    'Number of birthdays found today'
)

whatsapp_connection_status = Gauge(
    'whatsapp_connection_status',
    'WhatsApp connection status (1=connected, 0=disconnected)'
)

# API performance metrics
api_request_duration = Histogram(
    'api_request_duration_seconds',
    'API request duration in seconds',
    ['method', 'endpoint']
)

# VM Health metrics
vm_health_status = Gauge(
    'vm_health_status',
    'Overall VM health status (1=healthy, 0=unhealthy)'
)

def metrics_endpoint():
    """Prometheus metrics endpoint"""
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

def record_message_sent(group_name, message_type='birthday'):
    """Record a successful message"""
    messages_sent_total.labels(group=group_name, message_type=message_type).inc()

def record_message_failed(group_name, reason):
    """Record a failed message"""
    messages_failed_total.labels(group=group_name, reason=reason).inc()

def update_run_status(success=True, birthday_count=0):
    """Update daily run status"""
    if success:
        last_successful_run.set(time.time())
        daily_check_status.set(1)
    else:
        daily_check_status.set(0)
    
    birthdays_today.set(birthday_count)

def update_whatsapp_status(connected=True):
    """Update WhatsApp connection status"""
    whatsapp_connection_status.set(1 if connected else 0)
PYTHON

# 3. Update app.py to include metrics
echo ""
echo "3️⃣ Updating API to expose metrics..."
cat >> app/app.py << 'PYTHON'

# Add metrics endpoint
from metrics import metrics_endpoint, update_whatsapp_status
import requests

@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint"""
    # Update WhatsApp status before returning metrics
    try:
        response = requests.get('http://wppconnect-bot:3005/health', timeout=2)
        update_whatsapp_status(response.status_code == 200)
    except:
        update_whatsapp_status(False)
    
    return metrics_endpoint()
PYTHON

echo "✅ Metrics added to API"

# 4. Update birthday service to record metrics
echo ""
echo "4️⃣ Updating birthday service..."
cat > app/whatsapp/metrics_tracker.py << 'PYTHON'
import requests
import logging

logger = logging.getLogger(__name__)

METRICS_URL = "http://python-api:5000/metrics/record"

def record_message_sent(group_name, message_type='birthday'):
    """Record successful message to metrics"""
    try:
        requests.post(f"{METRICS_URL}/sent", 
                     json={'group': group_name, 'type': message_type},
                     timeout=2)
    except Exception as e:
        logger.debug(f"Failed to record metric: {e}")

def record_message_failed(group_name, reason):
    """Record failed message to metrics"""
    try:
        requests.post(f"{METRICS_URL}/failed",
                     json={'group': group_name, 'reason': reason},
                     timeout=2)
    except Exception as e:
        logger.debug(f"Failed to record metric: {e}")

def record_daily_run(success, birthday_count=0):
    """Record daily run completion"""
    try:
        requests.post(f"{METRICS_URL}/run",
                     json={'success': success, 'count': birthday_count},
                     timeout=2)
    except Exception as e:
        logger.debug(f"Failed to record metric: {e}")
PYTHON

echo "✅ Metrics tracking added"
echo ""
echo "==========================================="
echo "✅ Metrics setup complete!"
echo ""
echo "Rebuild API container:"
echo "  docker-compose build python-api"
echo "  docker-compose restart python-api"

