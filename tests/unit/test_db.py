# tests/unit/test_db.py
import pytest
from unittest.mock import patch, MagicMock
import sys
import os
from datetime import datetime

# Add app directory to Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '../../app'))

from app.lib.db import query_birthdays_by_date, add_birthday, update_birthday, delete_birthday

def test_query_birthdays_by_date():
    # Mock DynamoDB resource and table
    with patch('boto3.resource') as mock_resource:
        # Setup mock table and response
        mock_table = MagicMock()
        mock_resource.return_value.Table.return_value = mock_table
        
        # Mock query response
        mock_items = [
            {"id": "1", "name": "John Doe", "birth_date": "1990-03-15", "message": "Happy Birthday!"}
        ]
        mock_table.query.return_value = {"Items": mock_items}
        
        # Call function with test date
        date_str = "03-15"
        result = query_birthdays_by_date(date_str)
        
        # Verify query was called with correct parameters
        mock_table.query.assert_called_once()
        
        # Check results
        assert len(result) == 1
        assert result[0]['name'] == "John Doe"

def test_add_birthday():
    # Mock DynamoDB resource and table
    with patch('boto3.resource') as mock_resource:
        # Setup mock table
        mock_table = MagicMock()
        mock_resource.return_value.Table.return_value = mock_table
        
        # Test data
        birthday_data = {
            "name": "John Doe",
            "birth_date": "1990-03-15",
            "message": "Happy Birthday!"
        }
        
        # Call function
        result = add_birthday(birthday_data)
        
        # Verify put_item was called
        mock_table.put_item.assert_called_once()
        
        # Check that ID was generated
        assert 'id' in result
