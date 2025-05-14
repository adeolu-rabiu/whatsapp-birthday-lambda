import boto3
import json

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb', region_name='eu-west-2')
birthdays_table = dynamodb.Table('Birthdays')
groups_table = dynamodb.Table('WhatsAppGroups')

# Try to scan both tables
try:
    print("Scanning Birthdays table...")
    birthdays_response = birthdays_table.scan()
    print(f"Birthdays count: {len(birthdays_response.get('Items', []))}")
    print(json.dumps(birthdays_response.get('Items', [])[:2], indent=2))
except Exception as e:
    print(f"Error scanning Birthdays table: {e}")

try:
    print("\nScanning WhatsAppGroups table...")
    groups_response = groups_table.scan()
    print(f"Groups count: {len(groups_response.get('Items', []))}")
    print(json.dumps(groups_response.get('Items', [])[:2], indent=2))
except Exception as e:
    print(f"Error scanning WhatsAppGroups table: {e}")
