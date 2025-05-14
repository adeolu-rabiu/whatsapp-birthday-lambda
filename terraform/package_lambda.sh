#!/bin/bash

# Exit on error
set -e

echo "===== Packaging Lambda Tunnel Function ====="

# Create a temporary directory for packaging
TEMP_DIR="lambda_package_temp"
mkdir -p $TEMP_DIR
echo "Created temporary directory: $TEMP_DIR"

# Copy the Lambda function code
echo "Copying Lambda function code..."
cp lambda_tunnel.py $TEMP_DIR/

# Change to the temp directory
cd $TEMP_DIR

# Zip the Lambda package
echo "Creating Lambda package..."
zip -r ../lambda_tunnel_function.zip .

# Clean up
cd ..
echo "Cleaning up temporary directory..."
rm -rf $TEMP_DIR

echo "===== Lambda package created successfully: lambda_tunnel_function.zip ====="
echo "You can now run 'terraform apply' to deploy the Lambda function."
