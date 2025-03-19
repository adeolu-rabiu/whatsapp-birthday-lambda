import pytest
from unittest.mock import patch, MagicMock
import sys
import os
import json

# Add app directory to Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '../../app'))

# Import after path setup
from app.scheduler.handler import get_todays_birthdays, lambda_handler

# Mock boto3 to prevent region errors
@pytest.fixture(autouse=True)
def mock_boto3():
    with patch('boto3.client'):
        with patch('boto3.session.Session'):
            yield

def test_get_todays_birthdays():
    # Mock data for today's birthdays
    mock_data = [
        {"id": "1", "name": "John Doe", "birth_date": "1990-03-15", "message": "Happy Birthday!"},
        {"id": "2", "name": "Jane Smith", "birth_date": "1985-03-15", "message": "Celebrate well!"}
    ]
    
    # Mock the db module
    with patch('app.scheduler.handler.db.query_birthdays_by_date', return_value=mock_data):
        # Set today's date to March 15
        with patch('app.scheduler.handler.datetime') as mock_datetime:
            mock_datetime.now.return_value.strftime.return_value = "03-15"
            
            # Mock log_metrics to prevent actual AWS calls
            with patch('app.scheduler.handler.log_metrics'):
                birthdays = get_todays_birthdays()
                
                # Assert we get back our mock data
                assert len(birthdays) == 2
                assert birthdays[0]['name'] == "John Doe"
                assert birthdays[1]['name'] == "Jane Smith"

def test_lambda_handler():
    # Mock the scheduler functions
    with patch('app.scheduler.handler.get_todays_birthdays', return_value=[]) as mock_birthdays:
        with patch('app.scheduler.handler.whatsapp.send_birthday_messages') as mock_send:
            # Mock log_metrics to prevent actual AWS calls
            with patch('app.scheduler.handler.log_metrics') as mock_metrics:
                # Call lambda handler
                result = lambda_handler({}, {})
                
                # Verify the functions were called
                mock_birthdays.assert_called_once()
                mock_send.assert_called_once_with([])
                mock_metrics.assert_called_once_with(0, 0, 0)  # Verify metrics called with correct values
                
                # Check result has expected structure
                assert 'statusCode' in result
                assert result['statusCode'] == 200
                body = json.loads(result['body'])
                assert body['message'] == "Birthday notifications processed"
                assert body['birthdays_processed'] == 0

def test_lambda_handler_with_birthdays():
    # Mock data for today's birthdays
    mock_data = [
        {"id": "1", "name": "John Doe", "birth_date": "1990-03-15", "message": "Happy Birthday!"},
        {"id": "2", "name": "Jane Smith", "birth_date": "1985-03-15", "message": "Celebrate well!"}
    ]
    
    # Mock the scheduler functions
    with patch('app.scheduler.handler.get_todays_birthdays', return_value=mock_data) as mock_birthdays:
        with patch('app.scheduler.handler.whatsapp.send_birthday_messages') as mock_send:
            # Mock log_metrics to prevent actual AWS calls
            with patch('app.scheduler.handler.log_metrics') as mock_metrics:
                # Call lambda handler
                result = lambda_handler({}, {})
                
                # Verify the functions were called
                mock_birthdays.assert_called_once()
                assert mock_send.call_count == 2  # Called once for each birthday
                mock_metrics.assert_called_once_with(2, 2, 0)  # Verify metrics called with correct values
                
                # Check result has expected structure
                assert 'statusCode' in result
                assert result['statusCode'] == 200
                body = json.loads(result['body'])
                assert body['message'] == "Birthday notifications processed"
                assert body['birthdays_processed'] == 2
                assert body['messages_sent'] == 2
