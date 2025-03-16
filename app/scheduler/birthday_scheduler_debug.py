import sys
import os
import traceback
import json
import datetime

print("Starting birthday_scheduler.py")
print(f"Current directory: {os.getcwd()}")
print(f"Directory contents: {os.listdir('.')}")
print(f"Python path: {sys.path}")

try:
    print("Trying to import WhatsAppSender")
    from whatsapp.whatsapp_sender import WhatsAppSender
    print("Successfully imported WhatsAppSender")
except Exception as e:
    print(f"Error importing WhatsAppSender: {e}")
    traceback.print_exc()

# Import the rest of your dependencies with debug prints

def handler(event, context):
    print("Entering handler function")
    try:
        # Add print statements at key points in your handler logic
        print("Starting handler execution")
        
        # Your handler code here
        # Add more print statements throughout your logic
        
        print("Handler completed successfully")
        return {"statusCode": 200, "body": "Success"}
    except Exception as e:
        print(f"Error in handler: {e}")
        traceback.print_exc()
        return {"statusCode": 500, "body": str(e)}

if __name__ == "__main__":
    print("Running as main script")
    handler({}, None)
