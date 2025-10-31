#!/usr/bin/env python3
"""
DynamoDB Disaster Recovery Restore Script
Restores data from backup JSON files
"""
import json
import boto3
import sys
from pathlib import Path

def restore_table(table_name, backup_file):
    """Restore a DynamoDB table from backup"""
    print(f"📦 Restoring {table_name}...")
    
    dynamodb = boto3.resource('dynamodb', region_name='eu-west-2')
    table = dynamodb.Table(table_name)
    
    # Load backup
    with open(backup_file, 'r') as f:
        backup_data = json.load(f)
    
    items = backup_data.get('Items', [])
    print(f"   Found {len(items)} items to restore")
    
    # Restore items
    with table.batch_writer() as batch:
        for item in items:
            batch.put_item(Item=item)
    
    print(f"   ✅ Restored {len(items)} items to {table_name}")

def main():
    """Main restore function"""
    print("🔄 DynamoDB Disaster Recovery Restore")
    print("=" * 50)
    print()
    
    backup_dir = Path('backups')
    
    if not backup_dir.exists():
        print("❌ Backup directory not found!")
        sys.exit(1)
    
    # Restore tables
    tables = {
        'Birthdays': backup_dir / 'birthdays-backup.json',
        'WhatsAppGroups': backup_dir / 'whatsapp-groups-backup.json'
    }
    
    for table_name, backup_file in tables.items():
        if backup_file.exists():
            try:
                restore_table(table_name, backup_file)
            except Exception as e:
                print(f"❌ Error restoring {table_name}: {e}")
        else:
            print(f"⚠️  No backup found for {table_name}")
    
    print()
    print("=" * 50)
    print("✅ Restore complete!")

if __name__ == '__main__':
    main()
