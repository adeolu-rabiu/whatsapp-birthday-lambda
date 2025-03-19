import json
import boto3
import os
import uuid
from datetime import datetime

# Initialize DynamoDB resources
dynamodb = boto3.resource('dynamodb')
birthdays_table = dynamodb.Table(os.environ['BIRTHDAYS_TABLE'])
groups_table = dynamodb.Table(os.environ['GROUPS_TABLE'])

def handler(event, context):
    print(f"Event: {json.dumps(event)}")
    
    # Extract route key from event
    route_key = event.get('routeKey', '')
    
    # Common headers for CORS
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Content-Type': 'application/json'
    }
    
    # Handle OPTIONS requests for CORS
    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({'message': 'CORS preflight request successful'})
        }
    
    try:
        # Route request to appropriate handler
        if route_key == 'GET /birthdays':
            return get_birthdays(headers)
        elif route_key == 'POST /birthdays':
            return add_birthday(event, headers)
        elif route_key == 'GET /groups':
            return get_groups(headers)
        elif route_key == 'POST /groups':
            return add_group(event, headers)
        elif route_key == 'POST /test-message':
            return send_test_message(event, headers)
        else:
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({'error': 'Not Found'})
            }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }

def get_birthdays(headers):
    response = birthdays_table.scan()
    return {
        'statusCode': 200,
        'headers': headers,
        'body': json.dumps(response.get('Items', []))
    }

def add_birthday(event, headers):
    body = json.loads(event.get('body', '{}'))
    
    birthday_item = {
        'birthday_id': str(uuid.uuid4()),
        'name': body.get('name', ''),
        'birth_date': body.get('birthDate', ''),
        'group_id': body.get('groupId', ''),
        'birth_month_day': body.get('birthMonthDay', ''),  # Format: MM-DD
        'created_at': datetime.now().isoformat()
    }
    
    birthdays_table.put_item(Item=birthday_item)
    
    return {
        'statusCode': 201,
        'headers': headers,
        'body': json.dumps(birthday_item)
    }

def get_groups(headers):
    response = groups_table.scan()
    return {
        'statusCode': 200,
        'headers': headers,
        'body': json.dumps(response.get('Items', []))
    }

def add_group(event, headers):
    body = json.loads(event.get('body', '{}'))
    
    group_item = {
        'group_id': str(uuid.uuid4()),
        'name': body.get('name', ''),
        'description': body.get('description', ''),
        'created_at': datetime.now().isoformat()
    }
    
    groups_table.put_item(Item=group_item)
    
    return {
        'statusCode': 201,
        'headers': headers,
        'body': json.dumps(group_item)
    }

def send_test_message(event, headers):
    # This would call your WhatsApp sender Lambda
    # For now, we'll just return success
    return {
        'statusCode': 200,
        'headers': headers,
        'body': json.dumps({'message': 'Test message sent successfully'})
    }
