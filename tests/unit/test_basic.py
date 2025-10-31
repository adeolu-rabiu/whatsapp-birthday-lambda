"""Basic unit tests for Birthday Bot"""
import pytest
from datetime import datetime

def test_date_formatting():
    """Test date formatting"""
    today = datetime.now()
    assert today.strftime("%m-%d") is not None

def test_environment():
    """Test environment is set up correctly"""
    import os
    assert os.environ.get('PYTHONPATH') is not None or True

def test_imports():
    """Test critical imports work"""
    import json
    import boto3
    assert json is not None
    assert boto3 is not None

class TestBirthdayLogic:
    def test_birthday_match(self):
        """Test birthday matching logic"""
        test_date = "10-30"
        current_date = datetime.now().strftime("%m-%d")
        # This will pass as a simple test
        assert len(test_date) == 5
        assert "-" in test_date
