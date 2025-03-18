#!/bin/bash

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Install development dependencies
echo "Installing dependencies..."
pip install -r requirements-dev.txt

# Check if pytest is installed
if ! command -v pytest &> /dev/null; then
    echo "pytest could not be found, installing..."
    pip install pytest
fi

# Run unit tests
echo "Running unit tests..."
python -m pytest tests/unit -v || echo "No unit tests found or tests failed"

# Check if integration tests should be run
if [ "$1" == "--integration" ]; then
    echo "Running integration tests..."
    python -m pytest tests/integration -v || echo "No integration tests found or tests failed"
fi
