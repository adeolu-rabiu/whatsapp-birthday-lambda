import os
import logging
import requests
import datetime
import random
import json
import boto3
from pathlib import Path

# === Logging Setup ===
LOG_DIR = "/opt/whatsapp-birthday-lambda/logs"
os.makedirs(LOG_DIR, exist_ok=True)

LOG_FILE_PATH = os.path.join(LOG_DIR, "whatsapp_birthday_service.log")

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE_PATH),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger('whatsapp_birthday_service')

# === Config ===
WPP_BOT_URL = os.getenv('WPP_BOT_URL', 'http://wppconnect-bot:3005')
SEND_ENDPOINT = f"{WPP_BOT_URL}/send"
HEALTH_ENDPOINT = f"{WPP_BOT_URL}/health"
TEST_SEND_API_URL = "http://wppconnect-bot:3005/test-send"
BASE_DIR = Path(__file__).parent
FACT_LOG_PATH = BASE_DIR / '.used_fun_facts.log'
BASE_DIR = Path(__file__).parent
BASE_DIR = Path(__file__).parent
FACT_SOURCE_PATH = Path(os.getenv('FACT_SOURCE_PATH', BASE_DIR / 'fun_facts_no_blank_lines.txt'))

def normalize_group_name(name):
    """Normalize group name for better matching"""
    return name.lower().replace('_', ' ').strip()

def load_fun_fact():
    with open(FACT_SOURCE_PATH, "r", encoding="utf-8") as f:
        all_facts = [line.strip().strip('"') for line in f if line.strip()]

    used_facts = {}
    if FACT_LOG_PATH.exists():
        with open(FACT_LOG_PATH, "r", encoding="utf-8") as log:
            for line in log:
                date_str, fact = line.strip().split("||", 1)
                used_facts[fact] = datetime.datetime.strptime(date_str, "%Y-%m-%d")

    six_months_ago = datetime.datetime.now() - datetime.timedelta(days=180)
    fresh_facts = [f for f in all_facts if used_facts.get(f, datetime.datetime.min) < six_months_ago]
    if not fresh_facts:
        fresh_facts = all_facts

    selected = random.choice(fresh_facts)

    with open(FACT_LOG_PATH, "a", encoding="utf-8") as log:
        today = datetime.datetime.now().strftime("%Y-%m-%d")
        log.write(f"{today}||{selected}\n")

    return selected

def get_today_birthdays():
    today = datetime.datetime.now().strftime("%m-%d")
    logger.info(f"📅 Checking for birthdays on: {today}")
    
    try:
        # Connect directly to DynamoDB
        dynamodb = boto3.resource('dynamodb', region_name='eu-west-2')
        birthdays_table = dynamodb.Table('Birthdays')
        groups_table = dynamodb.Table('WhatsAppGroups')
        
        # Get all birthdays
        birthdays_response = birthdays_table.scan()
        birthdays = birthdays_response.get('Items', [])
        
        # Handle pagination if there are more results
        while 'LastEvaluatedKey' in birthdays_response:
            birthdays_response = birthdays_table.scan(ExclusiveStartKey=birthdays_response['LastEvaluatedKey'])
            birthdays.extend(birthdays_response.get('Items', []))
        
        todays_birthdays = [b for b in birthdays if b.get("birth_month_day") == today]
        
        # Get all groups
        groups_response = groups_table.scan()
        groups = groups_response.get('Items', [])
        
        # Handle pagination if there are more results
        while 'LastEvaluatedKey' in groups_response:
            groups_response = groups_table.scan(ExclusiveStartKey=groups_response['LastEvaluatedKey'])
            groups.extend(groups_response.get('Items', []))
        
        logger.info(f"Found {len(groups)} WhatsApp groups: {', '.join([g.get('name', 'Unknown') for g in groups])}")
        group_map = {g['group_id']: g['name'] for g in groups}
        
        return todays_birthdays, group_map
    
    except Exception as e:
        logger.error(f"❌ Error fetching data from DynamoDB: {e}")
        return [], {}

def send_message(group, message):
    """
    Send message to WhatsApp group with improved error handling and multiple matching strategies
    """
    logger.info(f"Attempting to send message to group: '{group}'")
    
    # Try different variations of the group name
    group_variants = [
        group,                     # Original name
        group.replace('_', ' '),   # Replace underscores with spaces
        group.strip(),             # Trim whitespace
        normalize_group_name(group) # Normalized version
    ]
    
    # Remove duplicates while preserving order
    group_variants = list(dict.fromkeys(group_variants))
    
    logger.info(f"Will try these group name variants: {group_variants}")
    
    # Try all variants with regular send endpoint
    for variant in group_variants:
        try:
            logger.info(f"Trying with group name variant: '{variant}'")
            payload = {"group": variant, "message": message}
            
            # Use a longer timeout
            res = requests.post(SEND_ENDPOINT, json=payload, timeout=15)
            
            if res.status_code == 200:
                logger.info(f"✅ Sent message to '{group}' (using variant '{variant}'): {message}")
                return True
            else:
                logger.warning(f"⚠️ Failed to send to '{variant}': {res.status_code} - {res.text}")
        except Exception as e:
            logger.warning(f"⚠️ Exception when sending to '{variant}': {e}")
    
    # If regular send endpoint failed with all variants, try the test-send endpoint
    try:
        logger.info(f"Trying test-send endpoint with original group name: '{group}'")
        payload = {"group": group}
        
        test_res = requests.post(TEST_SEND_API_URL, json=payload, timeout=15)
        
        if test_res.status_code == 200:
            logger.info(f"✅ Test message sent to '{group}' successfully")
            
            # If test message worked, try sending the actual message
            try:
                # Get the successful group info from the response
                test_data = test_res.json()
                successful_group = test_data.get('group', {}).get('name')
                
                if successful_group:
                    logger.info(f"Test succeeded with group name: '{successful_group}', now sending actual message")
                    payload = {"group": successful_group, "message": message}
                    res = requests.post(SEND_ENDPOINT, json=payload, timeout=15)
                    
                    if res.status_code == 200:
                        logger.info(f"✅ Sent actual message to '{successful_group}': {message}")
                        return True
                    else:
                        logger.error(f"❌ Failed to send actual message using name '{successful_group}': {res.status_code} - {res.text}")
                else:
                    logger.error("❌ Couldn't determine successful group name from test response")
            except Exception as e:
                logger.error(f"❌ Error sending actual message after test: {e}")
        else:
            logger.error(f"❌ Test-send failed: {test_res.status_code} - {test_res.text}")
            
            # Try to parse error info about available groups
            try:
                error_data = test_res.json()
                available_groups = error_data.get('availableGroups', [])
                if available_groups:
                    logger.info(f"Available groups according to test-send: {available_groups}")
                    
                    # Try one more time with an exact match if we can find one
                    normalized_group = normalize_group_name(group)
                    for available in available_groups:
                        available_name = available.get('name', '')
                        available_normalized = normalize_group_name(available_name)
                        
                        # Check if normalized versions match or are similar
                        if (available_normalized == normalized_group or
                            available_normalized in normalized_group or
                            normalized_group in available_normalized):
                            
                            logger.info(f"Found potential match: '{available_name}', trying it")
                            try:
                                payload = {"group": available_name, "message": message}
                                res = requests.post(SEND_ENDPOINT, json=payload, timeout=15)
                                
                                if res.status_code == 200:
                                    logger.info(f"✅ Sent message to '{available_name}': {message}")
                                    return True
                            except Exception as e:
                                logger.warning(f"⚠️ Failed with matched group '{available_name}': {e}")
            except Exception as e:
                logger.warning(f"⚠️ Error parsing available groups: {e}")
    except Exception as e:
        logger.error(f"❌ Error with test-send approach: {e}")
    
    # Get latest diagnostics
    try:
        # Check WhatsApp status
        status_url = "http://wppconnect-bot:3005/health"
        status_res = requests.get(status_url, timeout=5)
        logger.info(f"WhatsApp bot status: {status_res.status_code} - {status_res.text}")
        
        # Get detailed group info
        debug_url = "http://wppconnect-bot:3005/debug-groups"
        debug_res = requests.get(debug_url, timeout=5)
        if debug_res.status_code == 200:
            debug_data = debug_res.json()
            logger.info(f"Debug groups count: {debug_data.get('count', 0)}")
    except Exception as e:
        logger.error(f"❌ Failed to get diagnostic info: {e}")
    
    logger.error(f"❌ Failed to send to '{group}' after trying all methods")
    return False

def list_available_whatsapp_groups():
    try:
        status_url = "http://wppconnect-bot:3005/groups"
        res = requests.get(status_url, timeout=5)
        if res.status_code == 200:
            groups = res.json()
            if isinstance(groups, list):
                logger.info(f"Available WhatsApp groups from bot: {len(groups)} groups")
                for i, group in enumerate(groups):
                    logger.info(f"  Group {i+1}: {group.get('name')} (ID: {group.get('id')})")
                return groups
            else:
                logger.warning(f"Unexpected groups response format: {type(groups)}")
                logger.warning(f"Response content: {res.text[:500]}")
                return []
        else:
            logger.error(f"Failed to get groups: {res.status_code} - {res.text}")
            return []
    except Exception as e:
        logger.error(f"❌ Failed to list WhatsApp groups: {e}")
        return []

def main():
    logger.info("🚀 Starting WhatsApp Birthday Service")
    
    # Check the WhatsApp connection first
    try:
        status_url = "http://wppconnect-bot:3005/health"
        status_res = requests.get(status_url, timeout=5)
        logger.info(f"WhatsApp bot status: {status_res.status_code} - {status_res.text}")
        
        # List available groups
        available_groups = list_available_whatsapp_groups()
        logger.info(f"Found {len(available_groups)} groups directly from WhatsApp")
        
    except Exception as e:
        logger.error(f"❌ Failed to check WhatsApp bot status: {e}")
    
    birthdays, group_map = get_today_birthdays()

    groups_with_birthdays = set()

    if birthdays:
        for b in birthdays:
            name = b.get("name")
            group_id = b.get("group_id")
            group = group_map.get(group_id)
            if group:
                message = (
                    f"🎉 Happy Birthday, {name}! 🎂\n\n"
                    "Wishing you a wonderful birthday filled with joy and celebration. "
                    "May your day be as special as you are!\n\n- WhatsApp Birthday Bot"
                )
                success = send_message(group, message)
                if success:
                    groups_with_birthdays.add(group)
            else:
                logger.warning(f"⚠️ No group found for group_id '{group_id}'")

    # Send default message to remaining groups
    fun_fact = load_fun_fact()
    default_message = (
        "Village robot here with your daily fun fact...\n"
        "\n\n"
        f"💡 {fun_fact}"
    )
    if not birthdays:
        logger.info("📭 No birthdays today. Sending default to all groups.")
        targets = group_map.values()
    else:
        logger.info("📮 Sending default message to groups without birthdays.")
        targets = [g for g in group_map.values() if g not in groups_with_birthdays]

    for group in targets:
        send_message(group, default_message)

    # Force send a test message to all groups
    logger.info("🔍 Sending a verification message to ensure the system is working")
    test_message = f"🔧 System check at {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\nThis is an automated test to verify the WhatsApp Birthday Service is working correctly."
    
    # Get all available groups directly from WhatsApp
    available_groups = list_available_whatsapp_groups()
    if available_groups:
        for group in available_groups:
            group_name = group.get("name")
            if group_name:
                logger.info(f"📱 Sending test message to {group_name}")
                send_message(group_name, test_message)
    else:
        logger.error("❌ No WhatsApp groups available for testing")

if __name__ == "__main__":
    main()
