import pytest
from unittest.mock import patch, MagicMock
import sys
import os

# Add app directory to Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '../../app'))

from app.scheduler.handler import get_todays_birthdays, lambda_handler

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
            
            birthdays = get_todays_birthdays()
            
            # Assert we get back our mock data
            assert len(birthdays) == 2
            assert birthdays[0]['name'] == "John Doe"
            assert birthdays[1]['name'] == "Jane Smith"

def test_lambda_handler():
    # Mock the scheduler functions
    with patch('app.scheduler.handler.get_todays_birthdays', return_value=[]) as mock_birthdays:
        with patch('app.scheduler.handler.whatsapp.send_birthday_messages') as mock_send:
            # Call lambda handler
            result = lambda_handler({}, {})
            
            # Verify the functions were called
            mock_birthdays.assert_called_once()
            mock_send.assert_called_once_with([])
            
            # Check result has expected structure
            assert 'statusCode' in result
            assert result['statusCode'] == 200
