import os
import sys
import datetime
import json
import traceback

# Ensure root project directory is in sys.path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.append(project_root)

# Now import your modules using absolute imports with the correct class name
from app.whatsapp.whatsapp_sender import WhatsAppSender
from app.db.dynamodb_dao import BirthdayDAO  # Changed to BirthdayDAO instead of DynamoDBDao

def handler(event, context):
    print("Birthday scheduler lambda starting...")
    print(f"Python version: {sys.version}")
    print(f"Current directory: {os.getcwd()}")
    print(f"Directory contents: {os.listdir('.')}")

    try:
        # Initialize components
        print("Initializing components...")
        whatsapp = WhatsAppSender()
        db = BirthdayDAO()  # Use the correct class name here too

        # Get today's date in MM-DD format
        today = datetime.datetime.now().strftime("%m-%d")
        print(f"Looking for birthdays on date: {today}")

        # Get WhatsApp groups
        groups = db.get_whatsapp_groups()
        print(f"Found {len(groups)} WhatsApp groups")
        
        total_birthdays = 0
        
        # Process birthdays for each group
        for group in groups:
            group_id = group['group_id']
            group_name = group.get('name', 'Unknown Group')
            
            # Get birthdays for today in this group
            birthdays = db.get_todays_birthdays(group_id, today)
            print(f"Found {len(birthdays)} birthdays in group '{group_name}' for today")
            
            if birthdays:
                # Navigate to the group chat first
                whatsapp.navigate_to_group(group_name)
                
                # Send messages for each birthday in this group
                for birthday in birthdays:
                    message = f"Happy Birthday, {birthday['name']}! 🎂🎉"
                    whatsapp.send_message(message)
                    print(f"Birthday message sent for {birthday['name']} in group {group_name}")
                    total_birthdays += 1

        print("Birthday scheduler completed successfully")
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Birthday notifications processed successfully",
                "count": total_birthdays
            })
        }

    except Exception as e:
        print(f"Error in birthday scheduler: {e}")
        traceback.print_exc()
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": f"Error processing birthday notifications: {str(e)}"
            })
        }

if __name__ == "__main__":
    handler({}, None)
