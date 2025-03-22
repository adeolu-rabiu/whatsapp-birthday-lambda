import sys, os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from app.scheduler import handler

def lambda_handler(event, context):
    return handler.lambda_handler(event, context)


