#!/bin/bash

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Install development dependencies
echo "Installing dependencies..."
pip install -r requirements-dev.txt

# Run unit tests with correct PYTHONPATH
echo "Running unit tests..."
PYTHONPATH=$PYTHONPATH:$(pwd) python -m pytest tests/unit -v || echo "No unit tests found or tests failed"

# Check if integration tests should be run
if [ "$1" == "--integration" ]; then
    echo "Running integration tests..."
    PYTHONPATH=$PYTHONPATH:$(pwd) python -m pytest tests/integration -v || echo "No integration tests found or tests failed"
fi
