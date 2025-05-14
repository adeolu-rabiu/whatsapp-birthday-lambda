# Import the original handler
import sys
import traceback
import os
import time

# Print some debug information
print("Starting debug wrapper")
print(f"Current directory: {os.getcwd()}")
print(f"Files in current directory: {os.listdir('.')}")
print(f"Files in app/scheduler: {os.listdir('app/scheduler')}")
print(f"Python path: {sys.path}")

try:
    # Import the original handler
    from app.scheduler.birthday_scheduler import handler as original_handler
    
    # Wrap the handler
    def handler(event, context):
        print("Entering handler function")
        try:
            print("About to call original handler")
            result = original_handler(event, context)
            print("Handler function executed successfully")
            return result
        except Exception as e:
            print(f"Error in handler: {e}")
            traceback.print_exc()
            raise
except Exception as e:
    print(f"Error importing handler: {e}")
    traceback.print_exc()
