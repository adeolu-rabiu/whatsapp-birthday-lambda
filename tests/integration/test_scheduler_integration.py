# tests/integration/test_scheduler_integration.py
import pytest
import sys
import os
import json
import boto3
from datetime import datetime
from moto import mock_dynamodb

# Add app directory to Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '../../app'))

from app.scheduler.handler import lambda_handler
from app.lib.db import add_birthday, delete_birthday

@pytest.fixture(scope='function')
def aws_credentials():
    """Mocked AWS Credentials for boto3"""
    os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
    os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'
    os.environ['AWS_SECURITY_TOKEN'] = 'testing'
    os.environ['AWS_SESSION_TOKEN'] = 'testing'
    os.environ['AWS_DEFAULT_REGION'] = 'us-east-1'

@pytest.fixture(scope='function')
def dynamodb(aws_credentials):
    """Create a mock DynamoDB table"""
    with mock_dynamodb():
        # Create the DynamoDB table with both primary key and GSI for date queries
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.create_table(
            TableName='birthdays',
            KeySchema=[
                {'AttributeName': 'id', 'KeyType': 'HASH'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'id', 'AttributeType': 'S'},
                {'AttributeName': 'date_month_day', 'AttributeType': 'S'}
            ],
            GlobalSecondaryIndexes=[
                {
                    'IndexName': 'date_month_day-index',
                    'KeySchema': [
                        {'AttributeName': 'date_month_day', 'KeyType': 'HASH'},
                    ],
                    'Projection': {
                        'ProjectionType': 'ALL'
                    },
                    'ProvisionedThroughput': {
                        'ReadCapacityUnits': 5,
                        'WriteCapacityUnits': 5
                    }
                }
            ],
            ProvisionedThroughput={'ReadCapacityUnits': 5, 'WriteCapacityUnits': 5}
        )
        yield dynamodb

def setup_test_data():
    # Today's date in MM-DD format
    today = datetime.now().strftime("%m-%d")
    
    # Create test birthday for today
    test_birthday = {
        "name": "Integration Test User",
        "birth_date": f"2000-{today.split('-')[0]}-{today.split('-')[1]}",
        "date_month_day": today,
        "message": "Integration Test Message"
    }
    
    # Add to database
    result = add_birthday(test_birthday)
    return result

def teardown_test_data(birthday_id):
    # Remove test data
    delete_birthday(birthday_id)

def test_scheduler_integration(dynamodb):
    # Setup
    test_data = setup_test_data()
    
    try:
        # Call the lambda handler
        response = lambda_handler({}, {})
        
        # Verify response structure
        assert 'statusCode' in response
        assert response['statusCode'] == 200
        
        # Check body for success message
        body = json.loads(response['body'])
        assert 'message' in body
    finally:
        # Clean up test data
        teardown_test_data(test_data['id'])
