import os
import sys
import datetime
import json
import traceback

def handler(event, context):
    print("Birthday scheduler lambda starting...")
    print(f"Python version: {sys.version}")
    print(f"Current directory: {os.getcwd()}")
    print(f"Directory contents: {os.listdir('.')}")
    
    try:
        # Import dependencies
        print("Importing dependencies...")
        from whatsapp.whatsapp_sender import WhatsAppSender
        from db.dynamodb_dao import DynamoDBDao
        
        # Initialize components
        print("Initializing components...")
        whatsapp = WhatsAppSender()
        db = DynamoDBDao()
        
        # Get today's date
        today = datetime.datetime.now().strftime("%m-%d")
        print(f"Looking for birthdays on date: {today}")
        
        # Get birthdays for today
        birthdays = db.get_birthdays_for_date(today)
        
        # Send messages for each birthday
        for birthday in birthdays:
            message = f"Happy Birthday, {birthday['name']}!"
            whatsapp.send_message(birthday['phone'], message)
            print(f"Birthday message sent to {birthday['name']}")
        
        print("Birthday scheduler completed successfully")
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Birthday notifications processed successfully",
                "count": len(birthdays)
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
