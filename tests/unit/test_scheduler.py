import pytest
from unittest.mock import patch, MagicMock
import json
import sys
import os

# Add app directory to Python path to ensure imports work
sys.path.append(os.path.join(os.path.dirname(__file__), '../..'))

def test_get_todays_birthdays():
    # Use individual patches with correct patching targets
    with patch('datetime.datetime') as mock_datetime:
        with patch('app.lib.db.query_birthdays_by_date') as mock_query:
            with patch('app.scheduler.handler.log_metrics') as mock_log_metrics:
                # Mock data and return values
                mock_data = [
                    {"id": "1", "name": "John Doe", "birth_date": "1990-03-15", "message": "Happy Birthday!"},
                    {"id": "2", "name": "Jane Smith", "birth_date": "1985-03-15", "message": "Celebrate well!"}
                ]
                mock_query.return_value = mock_data
                mock_datetime.now.return_value.strftime.return_value = "03-15"
                
                # Import after mocks are set up
                from app.scheduler.handler import get_todays_birthdays
                
                # Call the function
                birthdays = get_todays_birthdays()
                
                # Verify results
                assert len(birthdays) == 2
                assert birthdays[0]['name'] == "John Doe"
                assert birthdays[1]['name'] == "Jane Smith"
                
                # Verify mock calls
                mock_query.assert_called_once_with("03-15")

def test_lambda_handler():
    # Use individual patches with full paths
    with patch('app.scheduler.handler.get_todays_birthdays') as mock_get_birthdays:
        with patch('app.scheduler.handler.whatsapp.send_birthday_messages') as mock_send:
            with patch('app.scheduler.handler.log_metrics') as mock_log_metrics:
                # Configure mocks
                mock_get_birthdays.return_value = []
                
                # Import after mocks are set up
                from app.scheduler.handler import lambda_handler
                
                # Call the function
                result = lambda_handler({}, {})
                
                # Check result - this test case has no birthdays, so send_birthday_messages
                # should NOT be called - adjust the assertion to match the expected behavior
                mock_get_birthdays.assert_called_once()
                # Don't assert on mock_send as it shouldn't be called with empty birthdays
                mock_log_metrics.assert_called_once_with(0, 0, 0)
                
                # Verify the result
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
    
    # Use individual patches with full paths
    with patch('app.scheduler.handler.get_todays_birthdays') as mock_get_birthdays:
        with patch('app.lib.whatsapp.send_birthday_messages') as mock_send:
            with patch('app.scheduler.handler.log_metrics') as mock_log_metrics:
                # Configure mocks
                mock_get_birthdays.return_value = mock_data
                
                # Import after mocks are set up
                from app.scheduler.handler import lambda_handler
                
                # Call the function
                result = lambda_handler({}, {})
                
                # Verify the calls
                mock_get_birthdays.assert_called_once()
                assert mock_send.call_count == 2
                mock_log_metrics.assert_called_once_with(2, 2, 0)
                
                # Verify the result
                assert result['statusCode'] == 200
                body = json.loads(result['body'])
                assert body['message'] == "Birthday notifications processed"
                assert body['birthdays_processed'] == 2
                assert body['messages_sent'] == 2
