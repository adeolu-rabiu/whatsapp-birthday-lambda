import boto3
import uuid
from datetime import datetime

def query_birthdays_by_date(date_str):
    """
    Query DynamoDB for birthdays on a specific date (MM-DD format)
    """
    # Get DynamoDB resource and table
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('birthdays')
    
    # Query for birthdays on this date using the GSI
    response = table.query(
        IndexName='date_month_day-index',
        KeyConditionExpression="date_month_day = :date",
        ExpressionAttributeValues={
            ":date": date_str
        }
    )
    
    return response.get('Items', [])

def add_birthday(birthday_data):
    """
    Add a new birthday to the database
    """
    # Generate a unique ID if not provided
    if 'id' not in birthday_data:
        birthday_data['id'] = str(uuid.uuid4())
    
    # Add date_month_day if not already present
    if 'date_month_day' not in birthday_data and 'birth_date' in birthday_data:
        # Extract MM-DD from birth_date (YYYY-MM-DD)
        parts = birthday_data['birth_date'].split('-')
        if len(parts) >= 3:
            birthday_data['date_month_day'] = f"{parts[1]}-{parts[2]}"
    
    # Get DynamoDB resource and table
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('birthdays')
    
    # Add to DynamoDB
    table.put_item(Item=birthday_data)
    
    return birthday_data

def update_birthday(birthday_id, birthday_data):
    """
    Update an existing birthday in the database
    """
    # Get DynamoDB resource and table
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('birthdays')
    
    # Ensure ID is in the data
    birthday_data['id'] = birthday_id
    
    # Update date_month_day if birth_date is updated
    if 'birth_date' in birthday_data:
        # Extract MM-DD from birth_date (YYYY-MM-DD)
        parts = birthday_data['birth_date'].split('-')
        if len(parts) >= 3:
            birthday_data['date_month_day'] = f"{parts[1]}-{parts[2]}"
    
    # Update in DynamoDB
    table.put_item(Item=birthday_data)
    
    return birthday_data

def delete_birthday(birthday_id):
    """
    Delete a birthday from the database
    """
    # Get DynamoDB resource and table
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('birthdays')
    
    # Delete from DynamoDB
    table.delete_item(
        Key={
            'id': birthday_id
        }
    )
    
    return {'id': birthday_id}
