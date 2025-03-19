import pytest
from unittest.mock import patch, MagicMock
import json
import datetime

# Don't import from app directly at the module level
# import what we needed inside each test function

def test_get_todays_birthdays():
    # First set up all the mocks
    mock_db = MagicMock()
    mock_datetime = MagicMock()
    mock_log_metrics = MagicMock()
    
    # Mock data for today's birthdays
    mock_data = [
        {"id": "1", "name": "John Doe", "birth_date": "1990-03-15", "message": "Happy Birthday!"},
        {"id": "2", "name": "Jane Smith", "birth_date": "1985-03-15", "message": "Celebrate well!"}
    ]
    
    # Configure the mocks
    mock_db.query_birthdays_by_date.return_value = mock_data
    mock_datetime.now.return_value.strftime.return_value = "03-15"
    
    # Set up the module patches
    module_patches = {
        'app.lib.db': mock_db,
        'datetime.datetime': mock_datetime,
        'app.scheduler.handler.log_metrics': mock_log_metrics
    }
    
    # Apply all patches
    with patch.multiple('', **module_patches):
        # NOW import the function - after all mocks are in place
        from app.scheduler.handler import get_todays_birthdays
        
        # Call the function
        birthdays = get_todays_birthdays()
        
        # Verify results
        assert len(birthdays) == 2
        assert birthdays[0]['name'] == "John Doe"
        assert birthdays[1]['name'] == "Jane Smith"
        
        # Verify mock calls
        mock_db.query_birthdays_by_date.assert_called_once_with("03-15")

def test_lambda_handler():
    # Set up mocks
    mock_get_birthdays = MagicMock(return_value=[])
    mock_send_messages = MagicMock()
    mock_log_metrics = MagicMock()
    
    # Apply patches
    with patch('app.scheduler.handler.get_todays_birthdays', mock_get_birthdays):
        with patch('app.lib.whatsapp.send_birthday_messages', mock_send_messages):
            with patch('app.scheduler.handler.log_metrics', mock_log_metrics):
                # Now import the function
                from app.scheduler.handler import lambda_handler
                
                # Call the function
                result = lambda_handler({}, {})
                
                # Verify the calls
                mock_get_birthdays.assert_called_once()
                mock_send_messages.assert_called_once_with([])
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
    
    # Set up mocks
    mock_get_birthdays = MagicMock(return_value=mock_data)
    mock_send_messages = MagicMock()
    mock_log_metrics = MagicMock()
    
    # Apply patches
    with patch('app.scheduler.handler.get_todays_birthdays', mock_get_birthdays):
        with patch('app.lib.whatsapp.send_birthday_messages', mock_send_messages):
            with patch('app.scheduler.handler.log_metrics', mock_log_metrics):
                # Now import the function
                from app.scheduler.handler import lambda_handler
                
                # Call the function
                result = lambda_handler({}, {})
                
                # Verify the calls
                mock_get_birthdays.assert_called_once()
                assert mock_send_messages.call_count == 2
                mock_log_metrics.assert_called_once_with(2, 2, 0)
                
                # Verify the result
                assert result['statusCode'] == 200
                body = json.loads(result['body'])
                assert body['message'] == "Birthday notifications processed"
                assert body['birthdays_processed'] == 2
                assert body['messages_sent'] == 2
