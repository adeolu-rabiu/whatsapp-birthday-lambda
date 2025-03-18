import pytest
from unittest.mock import patch, MagicMock
import sys
import os

# Add app directory to Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '../../app'))

from app.lib.whatsapp import send_birthday_messages, format_message

def test_format_message():
    # Test data
    birthday_data = {
        "name": "John Doe",
        "message": "Happy Birthday!"
    }
    
    # Format the message
    formatted = format_message(birthday_data)
    
    # Assert message is formatted correctly
    assert "John Doe" in formatted
    assert "Happy Birthday!" in formatted

def test_send_birthday_messages():
    # Mock birthdays
    mock_birthdays = [
        {"name": "John Doe", "message": "Happy Birthday!"},
        {"name": "Jane Smith", "message": "Celebrate well!"}
    ]
    
    # Mock the WhatsApp API client
    with patch('app.lib.whatsapp.WhatsAppClient') as mock_client:
        # Setup the mock
        mock_instance = MagicMock()
        mock_client.return_value = mock_instance
        
        # Call the function
        send_birthday_messages(mock_birthdays)
        
        # Assert send_message was called twice (once for each birthday)
        assert mock_instance.send_message.call_count == 2
