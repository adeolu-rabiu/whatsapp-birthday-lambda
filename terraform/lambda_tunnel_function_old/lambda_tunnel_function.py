import os
import json
import logging
import boto3
from datetime import datetime
import traceback

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
birthdays_table = dynamodb.Table('Birthdays')
groups_table = dynamodb.Table('WhatsAppGroups')

def handler(event, context):
    logger.info(f"Event received: {json.dumps(event)}")
    
    # Extract request details
    path = event.get("rawPath", "/")
    
    # API Gateway v2 provides method differently depending on integration
    method = None
    if "requestContext" in event and "http" in event["requestContext"]:
        method = event["requestContext"]["http"].get("method")
    if not method:
        method = event.get("httpMethod", "GET")
    
    # Add CORS headers
    headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token",
        "Access-Control-Allow-Methods": "OPTIONS,GET,POST,PUT,DELETE",
        "Content-Type": "application/json"
    }
    
    # Handle OPTIONS requests (CORS preflight)
    if method == "OPTIONS":
        return {
            "statusCode": 200,
            "headers": headers,
            "body": ""
        }
    
    try:
        # Get birthdays
        if path == "/birthdays" and method == "GET":
            response = birthdays_table.scan()
            items = response.get('Items', [])
            
            # Add pagination if needed
            while 'LastEvaluatedKey' in response:
                response = birthdays_table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
                items.extend(response.get('Items', []))
            
            return {
                "statusCode": 200,
                "headers": headers,
                "body": json.dumps(items)
            }
        
        # Get groups
        elif path == "/groups" and method == "GET":
            response = groups_table.scan()
            items = response.get('Items', [])
            
            # Add pagination if needed
            while 'LastEvaluatedKey' in response:
                response = groups_table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
                items.extend(response.get('Items', []))
            
            return {
                "statusCode": 200,
                "headers": headers,
                "body": json.dumps(items)
            }
        
        # Add birthday
        elif path == "/birthdays" and method == "POST":
            body = event.get("body", "{}")
            if event.get("isBase64Encoded", False):
                import base64
                body = base64.b64decode(body).decode("utf-8")
            
            try:
                data = json.loads(body)
            except json.JSONDecodeError:
                return {
                    "statusCode": 400,
                    "headers": headers,
                    "body": json.dumps({"message": "Invalid JSON body"})
                }
            
            # Generate a unique ID if not provided
            if "birthday_id" not in data:
                data["birthday_id"] = f"birthday_{datetime.now().strftime('%Y%m%d%H%M%S')}"
            
            birthdays_table.put_item(Item=data)
            
            return {
                "statusCode": 201,
                "headers": headers,
                "body": json.dumps({"message": "Birthday created", "data": data})
            }
        
        # Add group
        elif path == "/groups" and method == "POST":
            body = event.get("body", "{}")
            if event.get("isBase64Encoded", False):
                import base64
                body = base64.b64decode(body).decode("utf-8")
            
            try:
                data = json.loads(body)
            except json.JSONDecodeError:
                return {
                    "statusCode": 400,
                    "headers": headers,
                    "body": json.dumps({"message": "Invalid JSON body"})
                }
            
            # Generate a unique ID if not provided
            if "group_id" not in data:
                data["group_id"] = f"group_{datetime.now().strftime('%Y%m%d%H%M%S')}"
            
            groups_table.put_item(Item=data)
            
            return {
                "statusCode": 201,
                "headers": headers,
                "body": json.dumps({"message": "Group created", "data": data})
            }
        
        # Unsupported path/method
        else:
            return {
                "statusCode": 404,
                "headers": headers,
                "body": json.dumps({"message": f"Not found: {method} {path}"})
            }
    
    except Exception as e:
        error_trace = traceback.format_exc()
        logger.error(f"Error processing request: {str(e)}\n{error_trace}")
        
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({
                "message": "Internal Server Error",
                "detail": str(e)
            })
        }
