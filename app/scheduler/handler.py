import datetime
import json
import logging
import boto3
from app.lib import db, whatsapp

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Create CloudWatch client
cloudwatch = boto3.client('cloudwatch')

def log_metrics(birthdays_count, message_count, error_count=0):
    """
    Log custom metrics to CloudWatch
    """
    try:
        logger.info(f"Logging metrics: birthdays={birthdays_count}, messages={message_count}, errors={error_count}")
        cloudwatch.put_metric_data(
            Namespace='BirthdayBot',
            MetricData=[
                {
                    'MetricName': 'BirthdaysProcessed',
                    'Value': birthdays_count,
                    'Unit': 'Count'
                },
                {
                    'MetricName': 'MessagesSent',
                    'Value': message_count,
                    'Unit': 'Count'
                },
                {
                    'MetricName': 'Errors',
                    'Value': error_count,
                    'Unit': 'Count'
                }
            ]
        )
    except Exception as e:
        logger.error(f"Error logging metrics: {str(e)}")

def get_todays_birthdays():
    # Get today's date in MM-DD format
    today = datetime.datetime.now().strftime("%m-%d")
    logger.info(f"Checking birthdays for date: {today}")
    
    # Query DynamoDB for birthdays on this date
    try:
        birthdays = db.query_birthdays_by_date(today)
        logger.info(f"Found {len(birthdays)} birthdays today")
        return birthdays
    except Exception as e:
        logger.error(f"Error retrieving birthdays: {str(e)}")
        log_metrics(0, 0, 1)  # Log error metric
        return []

def lambda_handler(event, context):
    logger.info("Birthday notification lambda started")
    
    try:
        # Get today's birthdays
        birthdays = get_todays_birthdays()
        
        # Track successful messages and errors
        success_count = 0
        error_count = 0
        
        # Send WhatsApp messages
        if birthdays:
            for birthday in birthdays:
                try:
                    whatsapp.send_birthday_messages(birthday)
                    success_count += 1
                    logger.info(f"Successfully sent birthday message for {birthday.get('name', 'unknown')}")
                except Exception as e:
                    error_count += 1
                    logger.error(f"Error sending birthday message: {str(e)}")
        
        # Log metrics to CloudWatch
        log_metrics(len(birthdays), success_count, error_count)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': "Birthday notifications processed",
                'birthdays_processed': len(birthdays),
                'messages_sent': success_count,
                'errors': error_count
            })
        }
    except Exception as e:
        logger.error(f"Lambda execution failed: {str(e)}")
        log_metrics(0, 0, 1)  # Log error metric
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': f"Error: {str(e)}"
            })
        }
