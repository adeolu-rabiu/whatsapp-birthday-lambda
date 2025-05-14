import datetime
import json
import logging
import os
from app.lib import db, whatsapp

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def log_metrics(birthdays_count, message_count, error_count=0):
    try:
        logger.info(f"Logging metrics: birthdays={birthdays_count}, messages={message_count}, errors={error_count}")
        try:
            import boto3
            region = os.environ.get("AWS_DEFAULT_REGION", "eu-west-2")
            cloudwatch = boto3.client('cloudwatch', region_name=region)
            cloudwatch.put_metric_data(
                Namespace='BirthdayBot',
                MetricData=[
                    {'MetricName': 'BirthdaysProcessed', 'Value': birthdays_count, 'Unit': 'Count'},
                    {'MetricName': 'MessagesSent', 'Value': message_count, 'Unit': 'Count'},
                    {'MetricName': 'Errors', 'Value': error_count, 'Unit': 'Count'}
                ]
            )
        except Exception as e:
            logger.warning(f"Could not send metrics to CloudWatch: {str(e)}")
    except ImportError:
        logger.warning("boto3 not available, skipping CloudWatch metrics")

def get_todays_birthdays():
    today = datetime.datetime.now().strftime("%m-%d")
    logger.info(f"Checking birthdays for date: {today}")
    try:
        birthdays = db.query_birthdays_by_date(today)
        logger.info(f"Found {len(birthdays)} birthdays today")
        return birthdays
    except Exception as e:
        logger.error(f"Error retrieving birthdays: {str(e)}")
        log_metrics(0, 0, 1)
        return []

# Add CORS headers to any response
def add_cors_headers(response):
    headers = {
        'Access-Control-Allow-Origin': '*',  # Allow any origin
        'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
        'Access-Control-Allow-Credentials': 'true'
    }
    
    if 'headers' in response:
        response['headers'].update(headers)
    else:
        response['headers'] = headers
        
    return response

def lambda_handler(event, context):
    logger.info("Birthday notification lambda started")
    
    # Handle preflight OPTIONS request
    if event.get('httpMethod') == 'OPTIONS':
        return add_cors_headers({
            'statusCode': 200,
            'body': json.dumps({})
        })
    
    # 🔐 Token Auth
    AUTH_TOKEN = os.getenv("AUTH_TOKEN")
    headers = event.get("headers", {}) or {}
    received_token = headers.get("Authorization", "").replace("Bearer ", "").strip()

    if received_token != AUTH_TOKEN:
        logger.warning("Unauthorized request: missing or invalid token")
        return add_cors_headers({
            'statusCode': 401,
            'body': json.dumps({'message': 'Unauthorized'})
        })

    try:
        birthdays = get_todays_birthdays()
        success_count = 0
        error_count = 0

        if birthdays:
            for birthday in birthdays:
                try:
                    whatsapp.send_birthday_messages(birthday)
                    success_count += 1
                    logger.info(f"Successfully sent birthday message for {birthday.get('name', 'unknown')}")
                except Exception as e:
                    error_count += 1
                    logger.error(f"Error sending birthday message: {str(e)}")

        log_metrics(len(birthdays), success_count, error_count)
        return add_cors_headers({
            'statusCode': 200,
            'body': json.dumps({
                'message': "Birthday notifications processed",
                'birthdays_processed': len(birthdays),
                'messages_sent': success_count,
                'errors': error_count
            })
        })
    except Exception as e:
        logger.error(f"Lambda execution failed: {str(e)}")
        log_metrics(0, 0, 1)
        return add_cors_headers({
            'statusCode': 500,
            'body': json.dumps({'message': f"Error: {str(e)}"})
        })
