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
