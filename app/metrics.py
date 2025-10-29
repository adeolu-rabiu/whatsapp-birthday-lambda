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
