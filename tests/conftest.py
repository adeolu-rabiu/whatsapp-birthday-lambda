"""Pytest configuration"""
import os
import sys
import pytest

# Add project root to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

@pytest.fixture
def mock_env():
    """Mock environment variables"""
    return {
        'AWS_REGION': 'eu-west-2',
        'DYNAMODB_TABLE_NAME': 'Birthdays',
        'AUTH_TOKEN': 'test-token'
    }
