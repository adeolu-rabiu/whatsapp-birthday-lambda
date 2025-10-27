import boto3
import requests
from flask import jsonify

def sync_whatsapp_groups():
    """Sync WhatsApp groups to DynamoDB"""
    try:
        # Get groups from WhatsApp
        response = requests.get('http://wppconnect-bot:3005/groups', timeout=10)
        whatsapp_groups = response.json()
        
        # Connect to DynamoDB
        dynamodb = boto3.resource('dynamodb', region_name='eu-west-2')
        table = dynamodb.Table('WhatsAppGroups')
        
        # Sync each group
        for group in whatsapp_groups:
            group_id = group.get('id')
            group_name = group.get('name')
            
            if group_id and group_name:
                table.put_item(Item={
                    'group_id': group_id,
                    'name': group_name
                })
        
        return jsonify({
            'success': True,
            'synced': len(whatsapp_groups)
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
