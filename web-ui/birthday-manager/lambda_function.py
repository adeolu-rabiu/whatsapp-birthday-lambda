import json
import os
import logging
import boto3
from decimal import Decimal
import uuid
from datetime import datetime
import re

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB resources
dynamodb = boto3.resource('dynamodb')
birthdays_table = dynamodb.Table(os.environ.get('BIRTHDAYS_TABLE', 'Birthdays'))
groups_table = dynamodb.Table(os.environ.get('GROUPS_TABLE', 'WhatsAppGroups'))

def handler(event, context):
    """Lambda handler for birthday API"""
    # Log the entire event for debugging
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Extract path, method, and headers using multiple possible structures
    if 'requestContext' in event and 'http' in event.get('requestContext', {}):
        # API Gateway V2
        path = event.get('requestContext', {}).get('http', {}).get('path', '')
        http_method = event.get('requestContext', {}).get('http', {}).get('method', '')
    else:
        # API Gateway V1 or direct invocation
        path = event.get('path', '')
        http_method = event.get('httpMethod', '')
    
    logger.info(f"Processing request: {http_method} {path}")
    
    # Handle OPTIONS requests for CORS
    if http_method == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps({'message': 'CORS preflight successful'})
        }
    
    # Authorize request
    headers = event.get('headers', {}) or {}
    auth_result = authorize_request(headers)
    if auth_result.get('statusCode') != 200:
        return auth_result
    
    # Parse body if present
    body = {}
    if event.get('body'):
        try:
            body = json.loads(event.get('body'))
            logger.info(f"Request body: {json.dumps(body)}")
        except Exception as e:
            logger.error(f"Error parsing request body: {e}")
            return {
                'statusCode': 400,
                'headers': cors_headers(),
                'body': json.dumps({'error': f'Invalid request body: {str(e)}'})
            }
    
    # Extract path parameters
    path_params = event.get('pathParameters', {}) or {}
    
    # If path parameters not available directly, extract from path
    birthday_id = None
    if 'id' in path_params:
        birthday_id = path_params['id']
    elif '/birthdays/' in path:
        # Extract ID from the path
        match = re.search(r'/birthdays/([^/]+)', path)
        if match:
            birthday_id = match.group(1)
    
    if birthday_id:
        logger.info(f"Birthday ID from path: {birthday_id}")
    
    # Route request to appropriate handler
    try:
        # GET endpoints
        if http_method == 'GET':
            if path.endswith('/birthdays') or path == '/birthdays':
                return handle_get_birthdays()
            elif path.endswith('/groups') or path == '/groups':
                return handle_get_groups()
            elif path.endswith('/dashboards') or path == '/dashboards':
                return handle_get_dashboard()
            elif birthday_id and '/birthdays/' in path:
                return handle_get_birthday(birthday_id)
        
        # POST endpoints
        elif http_method == 'POST':
            if path.endswith('/birthdays') or path == '/birthdays':
                return handle_create_birthday(body)
            elif path.endswith('/groups') or path == '/groups':
                return handle_create_group(body)
            elif path.endswith('/test-message') or path == '/test-message':
                return handle_test_message(body)
        
        # PUT endpoints
        elif http_method == 'PUT' and birthday_id:
            return handle_update_birthday(birthday_id, body)
            
        # DELETE endpoints
        elif http_method == 'DELETE' and birthday_id:
            return handle_delete_birthday(birthday_id)
            
        # Default for unmatched routes
        return {
            'statusCode': 404,
            'headers': cors_headers(),
            'body': json.dumps({
                'error': f'Endpoint not found: {http_method} {path}',
                'available_endpoints': ['/groups', '/birthdays', '/dashboards', '/test-message', '/birthdays/{id}']
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        logger.error(f"Exception traceback: {__import__('traceback').format_exc()}")
        return {
            'statusCode': 500,
            'headers': cors_headers(),
            'body': json.dumps({'error': f'Internal server error: {str(e)}'})
        }

def authorize_request(headers):
    """Authorize the request using the Bearer token"""
    auth_header = headers.get('authorization', headers.get('Authorization', ''))
    
    if not auth_header:
        return {
            'statusCode': 401,
            'headers': cors_headers(),
            'body': json.dumps({'error': 'Unauthorized - No authorization header provided'})
        }
        
    if not auth_header.startswith('Bearer '):
        return {
            'statusCode': 401,
            'headers': cors_headers(),
            'body': json.dumps({'error': 'Unauthorized - Invalid token format'})
        }
    
    token = auth_header.replace('Bearer ', '')
    expected_token = os.environ.get('AUTH_TOKEN', '2e58df99b9011ea1257bef6c0026bc3b9a2daa3543ff6b8f241c129f09646a7a')
    
    if token != expected_token:
        return {
            'statusCode': 401,
            'headers': cors_headers(),
            'body': json.dumps({'error': 'Unauthorized - Invalid token'})
        }
    
    return {'statusCode': 200}

def handle_get_birthdays():
    """Handle GET /birthdays request"""
    try:
        response = birthdays_table.scan()
        birthdays = response.get('Items', [])
        
        # Process additional pages if DynamoDB response is paginated
        while 'LastEvaluatedKey' in response:
            response = birthdays_table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
            birthdays.extend(response.get('Items', []))
        
        logger.info(f"Retrieved {len(birthdays)} birthdays")
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps(birthdays, cls=DecimalEncoder)
        }
    except Exception as e:
        logger.error(f"Error getting birthdays: {str(e)}")
        return {
            'statusCode': 500,
            'headers': cors_headers(),
            'body': json.dumps({'error': str(e)})
        }

def handle_get_birthday(birthday_id):
    """Handle GET /birthdays/{id} request"""
    try:
        # Scan to find the record with the provided ID
        response = birthdays_table.scan(
            FilterExpression="birthday_id = :bid",
            ExpressionAttributeValues={":bid": birthday_id}
        )
        
        items = response.get('Items', [])
        if not items:
            return {
                'statusCode': 404,
                'headers': cors_headers(),
                'body': json.dumps({'error': 'Birthday not found'})
            }
        
        # Return the first matching item
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps(items[0], cls=DecimalEncoder)
        }
    except Exception as e:
        logger.error(f"Error getting birthday: {str(e)}")
        return {
            'statusCode': 500,
            'headers': cors_headers(),
            'body': json.dumps({'error': str(e)})
        }

def handle_create_birthday(body):
    """Handle POST /birthdays request"""
    try:
        logger.info(f"Creating birthday with data: {json.dumps(body)}")
        
        # Log all received fields to help debug
        logger.info(f"Received fields: {', '.join(body.keys())}")
        
        # Check for required fields
        missing_fields = []
        required_fields = ['name', 'birth_date', 'group_id']
        
        for field in required_fields:
            if field not in body or not body[field]:
                missing_fields.append(field)
        
        if missing_fields:
            return {
                'statusCode': 400,
                'headers': cors_headers(),
                'body': json.dumps({'error': f'Missing required fields: {", ".join(missing_fields)}'})
            }
        
        # Generate a unique ID
        birthday_id = str(uuid.uuid4())
        
        # Handle multiple date formats
        birth_date = body['birth_date']
        birth_month_day = None
        
        try:
            # Try common date formats
            for fmt in ['%Y-%m-%d', '%m/%d/%Y', '%Y/%m/%d', '%m-%d-%Y']:
                try:
                    date_obj = datetime.strptime(birth_date, fmt)
                    birth_month_day = f"{date_obj.month:02d}-{date_obj.day:02d}"
                    # Standardize to YYYY-MM-DD format
                    birth_date = date_obj.strftime('%Y-%m-%d')
                    break
                except ValueError:
                    continue
                    
            if not birth_month_day:
                raise ValueError(f"Couldn't parse date: {birth_date}")
                
        except Exception as e:
            logger.error(f"Date parsing error: {str(e)}")
            return {
                'statusCode': 400,
                'headers': cors_headers(),
                'body': json.dumps({'error': f'Invalid date format: {str(e)}. Please use YYYY-MM-DD format.'})
            }
        
        # Create the item
        birthday_item = {
            'birthday_id': birthday_id,
            'group_id': body['group_id'],
            'name': body['name'],
            'birth_date': birth_date,
            'birth_month_day': birth_month_day,
            'created_at': datetime.now().isoformat()
        }
        
        # Add optional fields
        for field in ['message', 'phone_number']:
            if field in body and body[field]:
                birthday_item[field] = body[field]
        
        # Save to DynamoDB
        birthdays_table.put_item(Item=birthday_item)
        
        return {
            'statusCode': 201,
            'headers': cors_headers(),
            'body': json.dumps(birthday_item)
        }
    except Exception as e:
        logger.error(f"Error creating birthday: {str(e)}")
        return {
            'statusCode': 500,
            'headers': cors_headers(),
            'body': json.dumps({'error': str(e)})
        }

def handle_update_birthday(birthday_id, body):
    """Handle PUT /birthdays/{id} request"""
    try:
        logger.info(f"Updating birthday {birthday_id} with data: {json.dumps(body)}")
        
        # For direct record lookups we need group_id
        if 'group_id' not in body:
            # Find by scanning
            scan_response = birthdays_table.scan(
                FilterExpression="birthday_id = :bid",
                ExpressionAttributeValues={":bid": birthday_id}
            )
            
            items = scan_response.get('Items', [])
            if not items:
                return {
                    'statusCode': 404,
                    'headers': cors_headers(),
                    'body': json.dumps({'error': f'Birthday with ID {birthday_id} not found'})
                }
            
            # Use the group_id from the existing record
            body['group_id'] = items[0]['group_id']
            logger.info(f"Found existing birthday, using group_id: {body['group_id']}")
        
        # Check if the birthday exists
        response = birthdays_table.get_item(
            Key={
                'birthday_id': birthday_id,
                'group_id': body['group_id']
            }
        )
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'headers': cors_headers(),
                'body': json.dumps({'error': 'Birthday not found with the provided ID and group'})
            }
        
        # Build update expression
        update_expression = "SET "
        expression_attr_values = {}
        expression_attr_names = {}
        
        # Handle updatable fields
        updatable_fields = ['name', 'birth_date', 'message', 'phone_number']
        for field in updatable_fields:
            if field in body and body[field] is not None:
                update_expression += f"#{field} = :{field}, "
                expression_attr_values[f":{field}"] = body[field]
                expression_attr_names[f"#{field}"] = field
        
        # Handle birth_month_day if birth_date was updated
        if 'birth_date' in body and body['birth_date']:
            try:
                # Try common date formats
                birth_date = body['birth_date']
                for fmt in ['%Y-%m-%d', '%m/%d/%Y', '%Y/%m/%d', '%m-%d-%Y']:
                    try:
                        date_obj = datetime.strptime(birth_date, fmt)
                        birth_month_day = f"{date_obj.month:02d}-{date_obj.day:02d}"
                        # Update the standardized date format
                        expression_attr_values[":birth_date"] = date_obj.strftime('%Y-%m-%d')
                        break
                    except ValueError:
                        continue
                
                update_expression += "#birth_month_day = :birth_month_day, "
                expression_attr_values[":birth_month_day"] = birth_month_day
                expression_attr_names["#birth_month_day"] = "birth_month_day"
            except Exception as e:
                return {
                    'statusCode': 400,
                    'headers': cors_headers(),
                    'body': json.dumps({'error': f'Invalid date format: {str(e)}. Please use YYYY-MM-DD format.'})
                }
        
        # Add updated_at timestamp
        update_expression += "#updated_at = :updated_at"
        expression_attr_values[":updated_at"] = datetime.now().isoformat()
        expression_attr_names["#updated_at"] = "updated_at"
        
        logger.info(f"Update expression: {update_expression}")
        logger.info(f"Expression attribute values: {json.dumps(expression_attr_values)}")
        logger.info(f"Expression attribute names: {json.dumps(expression_attr_names)}")
        
        # Update the item
        try:
            response = birthdays_table.update_item(
                Key={
                    'birthday_id': birthday_id,
                    'group_id': body['group_id']
                },
                UpdateExpression=update_expression,
                ExpressionAttributeValues=expression_attr_values,
                ExpressionAttributeNames=expression_attr_names,
                ReturnValues="ALL_NEW"
            )
            
            logger.info(f"Update response: {json.dumps(response)}")
            
            return {
                'statusCode': 200,
                'headers': cors_headers(),
                'body': json.dumps(response.get('Attributes', {}), cls=DecimalEncoder)
            }
        except Exception as e:
            logger.error(f"Error in DynamoDB update: {str(e)}")
            logger.error(f"Exception traceback: {__import__('traceback').format_exc()}")
            return {
                'statusCode': 500,
                'headers': cors_headers(),
                'body': json.dumps({'error': f'Error updating in DynamoDB: {str(e)}'})
            }
    except Exception as e:
        logger.error(f"Error updating birthday: {str(e)}")
        logger.error(f"Exception traceback: {__import__('traceback').format_exc()}")
        return {
            'statusCode': 500,
            'headers': cors_headers(),
            'body': json.dumps({'error': str(e)})
        }

def handle_delete_birthday(birthday_id):
    """Handle DELETE /birthdays/{id} request"""
    try:
        # Scan to find the record with the provided ID
        response = birthdays_table.scan(
            FilterExpression="birthday_id = :bid",
            ExpressionAttributeValues={":bid": birthday_id}
        )
        
        items = response.get('Items', [])
        if not items:
            return {
                'statusCode': 404,
                'headers': cors_headers(),
                'body': json.dumps({'error': 'Birthday not found'})
            }
        
        # Assuming the first match is the one we want
        item = items[0]
        group_id = item.get('group_id')
        
        # Delete the item
        birthdays_table.delete_item(
            Key={
                'birthday_id': birthday_id,
                'group_id': group_id
            }
        )
        
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps({'message': 'Birthday deleted successfully'})
        }
    except Exception as e:
        logger.error(f"Error deleting birthday: {str(e)}")
        return {
            'statusCode': 500,
            'headers': cors_headers(),
            'body': json.dumps({'error': str(e)})
        }

def handle_get_groups():
    """Handle GET /groups request"""
    try:
        response = groups_table.scan()
        groups = response.get('Items', [])
        
        # Process additional pages if DynamoDB response is paginated
        while 'LastEvaluatedKey' in response:
            response = groups_table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
            groups.extend(response.get('Items', []))
        
        logger.info(f"Retrieved {len(groups)} groups")
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps(groups, cls=DecimalEncoder)
        }
    except Exception as e:
        logger.error(f"Error getting groups: {str(e)}")
        return {
            'statusCode': 500,
            'headers': cors_headers(),
            'body': json.dumps({'error': str(e)})
        }

def handle_create_group(body):
    """Handle POST /groups request"""
    try:
        logger.info(f"Creating group: {json.dumps(body)}")
        
        # Validate required fields
        required_fields = ['name']
        for field in required_fields:
            if field not in body:
                return {
                    'statusCode': 400,
                    'headers': cors_headers(),
                    'body': json.dumps({'error': f'Missing required field: {field}'})
                }
        
        # Generate a unique ID
        group_id = str(uuid.uuid4())
        
        # Create the item
        group_item = {
            'group_id': group_id,
            'name': body['name'],
            'created_at': datetime.now().isoformat()
        }
        
        # Add optional fields
        for field in ['description', 'phone_number']:
            if field in body and body[field]:
                group_item[field] = body[field]
        
        # Save to DynamoDB
        groups_table.put_item(Item=group_item)
        
        return {
            'statusCode': 201,
            'headers': cors_headers(),
            'body': json.dumps(group_item)
        }
    except Exception as e:
        logger.error(f"Error creating group: {str(e)}")
        return {
            'statusCode': 500,
            'headers': cors_headers(),
            'body': json.dumps({'error': str(e)})
        }

def handle_get_dashboard():
    """Handle GET /dashboards request"""
    try:
        # Get birthday count
        birthday_response = birthdays_table.scan(Select="COUNT")
        birthday_count = birthday_response.get('Count', 0)
        
        # Get group count
        group_response = groups_table.scan(Select="COUNT")
        group_count = group_response.get('Count', 0)
        
        # Get upcoming birthdays (simplified - just get a few)
        upcoming_birthdays = []
        if birthday_count > 0:
            birthday_items = birthdays_table.scan(Limit=5).get('Items', [])
            upcoming_birthdays = birthday_items
        
        dashboard = {
            'birthdays_count': birthday_count,
            'groups_count': group_count,
            'upcoming_birthdays': upcoming_birthdays
        }
        
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps(dashboard, cls=DecimalEncoder)
        }
    except Exception as e:
        logger.error(f"Error getting dashboard: {str(e)}")
        return {
            'statusCode': 500,
            'headers': cors_headers(),
            'body': json.dumps({'error': str(e)})
        }

def handle_test_message(body):
    """Handle POST /test-message request"""
    try:
        logger.info(f"Test message request: {json.dumps(body)}")
        
        # Implement test message functionality here, for now return success
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps({
                'message': 'Test message sent successfully',
                'timestamp': datetime.now().isoformat()
            })
        }
    except Exception as e:
        logger.error(f"Error sending test message: {str(e)}")
        return {
            'statusCode': 500,
            'headers': cors_headers(),
            'body': json.dumps({'error': str(e)})
        }

def cors_headers():
    """Return standard CORS headers"""
    return {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
        'Content-Type': 'application/json'
    }

class DecimalEncoder(json.JSONEncoder):
    """Helper class for serializing Decimal values from DynamoDB"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)
