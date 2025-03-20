import sys
import os

# Add project root to path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

# Import the Lambda handler
from app.scheduler.handler import lambda_handler

# Execute the handler with empty event and context
response = lambda_handler({}, {})
print(f"Lambda executed with response: {response}")
