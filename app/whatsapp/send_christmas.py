#!/usr/bin/env python3
"""
O-BOT Christmas Broadcast Script
Uses wppconnect API directly - NO extra dependencies needed!
"""

import requests
import time
import json
from datetime import datetime

# wppconnect API endpoint (adjust port if different)
WPPCONNECT_URL = "http://localhost:3005"  # Your wppconnect port

# Your WhatsApp groups - ALL 7 GROUPS
GROUPS = [
    "120363122719208363@g.us",       # Huawei UK Alumni
    "2348032005112-1455266657@g.us", # Family Forum
    "120363268858955463@g.us",       # Family_Corner
    "2348032005112-1591465760@g.us", # OneAsset Limited
    "120363150262893874@g.us",       # IT_Study_Group
    "2348032022371-1468653881@g.us", # OSU 06:07
    "120363424322618204@g.us",       # Nigerians in Farington Mews
]

# Christmas Message - Simple and Sweet with Cool Emojis
CHRISTMAS_MESSAGE = """🎄✨ *Merry Christmas from O-bot* 🎅🏾🎁

Wishing everyone in this group love ❤️, good health 🌟, and plenty of joyful moments today 🎉.

Enjoy the celebrations and stay blessed! 🙏🏾✨

🎄🎊 *Happy Holidays!* 🎊🎄"""

def send_message_via_wppconnect(group_id, message):
    """
    Send message using wppconnect API
    Returns: True if successful, False otherwise
    """
    try:
        url = f"{WPPCONNECT_URL}/api/whatsappbot/send-message"
        
        payload = {
            "chatId": group_id,
            "message": message,
            "isGroup": True
        }
        
        response = requests.post(
            url,
            json=payload,
            timeout=30
        )
        
        if response.status_code == 200:
            return True
        else:
            print(f"   ❌ Error: HTTP {response.status_code}")
            return False
            
    except Exception as e:
        print(f"   ❌ Error: {str(e)}")
        return False

def send_christmas_broadcast(delay_seconds=5):
    """
    Send Christmas message to all groups
    """
    print("=" * 60)
    print("🎄 STARTING CHRISTMAS BROADCAST")
    print("=" * 60)
    print(f"📊 Total groups: {len(GROUPS)}")
    print(f"⏱️  Delay between messages: {delay_seconds} seconds")
    print("=" * 60)
    
    success_count = 0
    fail_count = 0
    failed_groups = []
    
    group_names = [
        "Huawei UK Alumni",
        "Family Forum",
        "Family_Corner",
        "OneAsset Limited",
        "IT_Study_Group",
        "OSU 06:07",
        "Nigerians in Farington Mews",
    ]
    
    for i, (group_id, name) in enumerate(zip(GROUPS, group_names), 1):
        print(f"\n📤 Sending to group {i}/{len(GROUPS)}: {name}")
        print(f"   ID: {group_id}")
        
        result = send_message_via_wppconnect(group_id, CHRISTMAS_MESSAGE)
        
        if result:
            success_count += 1
            print(f"   ✅ Successfully sent!")
        else:
            fail_count += 1
            failed_groups.append(name)
            print(f"   ❌ Failed to send")
        
        # Wait between messages (except after last one)
        if i < len(GROUPS):
            print(f"   ⏳ Waiting {delay_seconds} seconds...")
            time.sleep(delay_seconds)
    
    # Final summary
    print("\n" + "=" * 60)
    print("🎄 BROADCAST COMPLETE!")
    print("=" * 60)
    print(f"✅ Successful: {success_count}")
    print(f"❌ Failed: {fail_count}")
    print(f"📊 Total: {len(GROUPS)}")
    
    if failed_groups:
        print(f"\n❌ Failed groups:")
        for name in failed_groups:
            print(f"   - {name}")
        print(f"\n💡 Tip: Restart WhatsApp connection and try again")
        print(f"   ./service_manager.sh → Option 6")
    
    print("=" * 60)

def preview_message():
    """Preview the message before sending"""
    print("=" * 60)
    print("🎄 CHRISTMAS MESSAGE PREVIEW")
    print("=" * 60)
    print(CHRISTMAS_MESSAGE)
    print("=" * 60)
    print(f"\n📊 Will be sent to {len(GROUPS)} groups:")
    
    group_names = [
        "Huawei UK Alumni",
        "Family Forum",
        "Family_Corner",
        "OneAsset Limited",
        "IT_Study_Group",
        "OSU 06:07",
        "Nigerians in Farington Mews",
    ]
    
    for i, (gid, name) in enumerate(zip(GROUPS, group_names), 1):
        print(f"   {i}. {name}")
        print(f"      {gid}")
    
    print("=" * 60)

def test_connection():
    """Test if wppconnect is accessible"""
    try:
        response = requests.get(f"{WPPCONNECT_URL}/api/whatsappbot/getAllGroups", timeout=5)
        if response.status_code == 200:
            groups = response.json()
            print(f"✅ Connected to wppconnect!")
            print(f"📊 Found {len(groups)} groups")
            return True
        else:
            print(f"❌ wppconnect returned HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Cannot connect to wppconnect: {e}")
        print(f"\n💡 Make sure wppconnect is running:")
        print(f"   docker ps | grep wpp")
        print(f"   ./service_manager.sh → Check Connection Status")
        return False

if __name__ == "__main__":
    import sys
    
    # Usage:
    # python3 send_christmas.py preview
    # python3 send_christmas.py test
    # python3 send_christmas.py send
    # python3 send_christmas.py send 10  (with 10 second delay)
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  Preview: python3 send_christmas.py preview")
        print("  Test:    python3 send_christmas.py test")
        print("  Send:    python3 send_christmas.py send [delay_seconds]")
        print("\nDefault delay: 5 seconds between messages")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "preview":
        preview_message()
    
    elif command == "test":
        print("\n🔍 Testing wppconnect connection...\n")
        test_connection()
    
    elif command == "send":
        # Test connection first
        print("\n🔍 Testing wppconnect connection...\n")
        if not test_connection():
            print("\n❌ Cannot proceed - wppconnect not accessible")
            sys.exit(1)
        
        delay = int(sys.argv[2]) if len(sys.argv) > 2 else 5
        
        print(f"\n⚠️  You're about to send Christmas message to {len(GROUPS)} groups")
        print(f"⏱️  Delay between messages: {delay} seconds\n")
        
        # Show preview first
        preview_message()
        
        print("\n")
        confirm = input("Type 'YES' to confirm and send: ")
        if confirm.upper() == "YES":
            print("")
            send_christmas_broadcast(delay)
        else:
            print("❌ Broadcast cancelled.")
    
    else:
        print(f"Unknown command: {command}")
        print("Use 'preview', 'test', or 'send'")
