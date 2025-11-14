#!/usr/bin/env python3

# Read the current file
with open('whatsapp_birthday_service.py', 'r') as f:
    content = f.read()

# Find and replace the send_message function
old_function_start = 'def send_message(group, message):'
new_function = '''def send_message(group, message):
    """
    Send message to WhatsApp group by finding the group ID first
    """
    logger.info(f"Attempting to send message to group: '{group}'")
    
    # First, get all groups from wppconnect to find the matching ID
    try:
        groups_response = requests.get(f"{WPP_BOT_URL}/groups", timeout=5)
        if groups_response.status_code == 200:
            wpp_groups = groups_response.json()
            
            # Try different variations of the group name
            group_variants = [
                group,                      # Original name
                group.replace('_', ' '),    # Replace underscores with spaces
                group.strip(),              # Trim whitespace
                group + ' ',                # Add trailing space (for cached names)
                group.strip() + ' ',        # Trim then add trailing space
                normalize_group_name(group) # Normalized version
            ]
            
            # Remove duplicates while preserving order
            group_variants = list(dict.fromkeys(group_variants))
            
            logger.info(f"Will try these group name variants: {group_variants}")
            
            # Find matching group
            matched_group = None
            for variant in group_variants:
                for wpp_group in wpp_groups:
                    wpp_name = wpp_group.get('name', '')
                    if wpp_name == variant or normalize_group_name(wpp_name) == normalize_group_name(variant):
                        matched_group = wpp_group
                        logger.info(f"✅ Matched variant '{variant}' to wppconnect group '{wpp_name}' (ID: {wpp_group.get('id')})")
                        break
                if matched_group:
                    break
            
            if matched_group:
                group_id = matched_group.get('id')
                group_name = matched_group.get('name')
                
                # Try sending with the ID (preferred)
                try:
                    payload = {"chatId": group_id, "message": message}
                    res = requests.post(f"{WPP_BOT_URL}/send-message", json=payload, timeout=15)
                    
                    if res.status_code == 200:
                        logger.info(f"✅ Sent message to '{group_name}' using ID: {message[:50]}...")
                        return True
                    else:
                        logger.warning(f"⚠️ Failed with ID, trying with name: {res.status_code}")
                except Exception as e:
                    logger.warning(f"⚠️ Exception with ID method: {e}")
                
                # Fallback: try with exact name from wppconnect
                try:
                    payload = {"group": group_name, "message": message}
                    res = requests.post(SEND_ENDPOINT, json=payload, timeout=15)
                    
                    if res.status_code == 200:
                        logger.info(f"✅ Sent message to '{group_name}' using name: {message[:50]}...")
                        return True
                    else:
                        logger.warning(f"⚠️ Failed with name too: {res.status_code} - {res.text}")
                except Exception as e:
                    logger.warning(f"⚠️ Exception with name method: {e}")
            else:
                logger.error(f"❌ Could not find group '{group}' in wppconnect groups")
                logger.info(f"Available groups: {[g.get('name') for g in wpp_groups]}")
        else:
            logger.error(f"❌ Failed to get groups from wppconnect: {groups_response.status_code}")
    except Exception as e:
        logger.error(f"❌ Exception getting groups from wppconnect: {e}")
    
    # Old fallback method - try all variants with regular send endpoint
    logger.info("Trying fallback method with all variants...")
    group_variants = [
        group,
        group.replace('_', ' '),
        group.strip(),
        group + ' ',
        group.strip() + ' ',
        normalize_group_name(group)
    ]
    group_variants = list(dict.fromkeys(group_variants))
    
    for variant in group_variants:
        try:
            logger.info(f"Trying variant: '{variant}'")
            payload = {"group": variant, "message": message}
            res = requests.post(SEND_ENDPOINT, json=payload, timeout=15)
            
            if res.status_code == 200:
                logger.info(f"✅ Sent with variant '{variant}': {message[:50]}...")
                return True
        except Exception as e:
            logger.warning(f"⚠️ Exception with variant '{variant}': {e}")
    
    logger.error(f"❌ Failed to send to '{group}' after trying all methods")
    return False'''

# Find the function and replace it
import re

# Find the entire send_message function (until the next def or until list_available_whatsapp_groups)
pattern = r'def send_message\(group, message\):.*?(?=def list_available_whatsapp_groups|def main\(\):|\Z)'
match = re.search(pattern, content, re.DOTALL)

if match:
    # Replace the function
    content = content[:match.start()] + new_function + '\n\n' + content[match.end():]
    
    # Write back
    with open('whatsapp_birthday_service.py', 'w') as f:
        f.write(content)
    
    print("✅ send_message function updated!")
    print("   Now fetches groups from wppconnect first")
    print("   Matches name variants to find correct group ID")
    print("   Sends using group ID (most reliable)")
else:
    print("❌ Could not find send_message function")

