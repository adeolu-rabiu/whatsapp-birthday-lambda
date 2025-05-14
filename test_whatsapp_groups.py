#!/usr/bin/env python3
import requests
import json
import sys
import logging
import argparse
import datetime

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger()

def get_whatsapp_status():
    try:
        res = requests.get("http://localhost:3005/status", timeout=5)
        logger.info(f"WhatsApp status: {res.status_code}")
        if res.status_code == 200:
            return res.json()
        return None
    except Exception as e:
        logger.error(f"Error checking WhatsApp status: {e}")
        return None

def list_whatsapp_groups():
    try:
        res = requests.get("http://localhost:3005/groups", timeout=5)
        logger.info(f"Groups API response: {res.status_code}")
        if res.status_code == 200:
            groups = res.json()
            return groups
        return []
    except Exception as e:
        logger.error(f"Error listing groups: {e}")
        return []

def send_test_message(group_name):
    try:
        # Prepare the timestamp outside the f-string
        timestamp = datetime.datetime.now().isoformat()
        payload = {"group": group_name, "message": f"Test message to {group_name} at {timestamp}"}
        
        res = requests.post("http://localhost:3005/send", json=payload, timeout=15)
        logger.info(f"Send response: {res.status_code}")
        if res.status_code == 200:
            logger.info(f"Successfully sent message to {group_name}")
            return True
        else:
            logger.warning(f"Failed to send message to {group_name}: {res.text}")
            return False
    except Exception as e:
        logger.error(f"Error sending message: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Test WhatsApp Groups')
    parser.add_argument('--test', help='Test sending to a specific group')
    parser.add_argument('--list-groups', action='store_true', help='List all available groups')
    args = parser.parse_args()

    # Check WhatsApp status first
    status = get_whatsapp_status()
    if not status or not status.get('connected'):
        logger.error("WhatsApp is not connected!")
        return 1

    logger.info(f"WhatsApp is connected as: {status.get('user', {}).get('name')}")

    # List groups
    if args.list_groups:
        groups = list_whatsapp_groups()
        if isinstance(groups, list):
            logger.info(f"Found {len(groups)} groups:")
            for i, group in enumerate(groups):
                logger.info(f"  {i+1}. {group.get('name')} (ID: {group.get('id')})")
        else:
            logger.warning(f"Unexpected groups response format: {type(groups)}")
            logger.warning(f"Raw response: {groups}")

    # Test sending to a specific group
    if args.test:
        logger.info(f"Testing message to group: {args.test}")
        success = send_test_message(args.test)
        if success:
            logger.info("Test message sent successfully!")
        else:
            logger.error("Failed to send test message")
            
            # Try the test-send endpoint as a fallback
            try:
                logger.info(f"Trying test-send endpoint...")
                test_payload = {"group": args.test}
                test_res = requests.post("http://localhost:3005/test-send", json=test_payload, timeout=15)
                
                if test_res.status_code == 200:
                    logger.info(f"Test-send succeeded: {test_res.text}")
                else:
                    logger.error(f"Test-send failed: {test_res.status_code} - {test_res.text}")
            except Exception as e:
                logger.error(f"Error with test-send: {e}")

    return 0

if __name__ == "__main__":
    sys.exit(main())
