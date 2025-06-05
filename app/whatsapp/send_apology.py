import requests
import json

# Your groups from the logs
groups = [
    "Family Forum", 
    "IT_Study_Group", 
    "Home Curricula", 
    "Family_Corner", 
    "Huawei UK Alumni", 
    "OneAsset Limited"
]

apology_message = """Really sorry your loved bot was down for 48 hours, outage is sincerely regretted. We are back and better, ready to celebrate you on your special days! 🤖❤️"""

BAILEYS_API_URL = "http://localhost:3005/send"

for group in groups:
    try:
        payload = {"group": group, "message": apology_message}
        response = requests.post(BAILEYS_API_URL, json=payload, timeout=10)
        if response.status_code == 200:
            print(f"✅ Sent apology to '{group}'")
        else:
            print(f"❌ Failed to send to '{group}': {response.status_code} - {response.text}")
    except Exception as e:
        print(f"❌ Error sending to '{group}': {e}")
    
    # Small delay between messages
    import time
    time.sleep(2)

print("🎉 Apology messages sent!")
