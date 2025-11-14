#!/usr/bin/env python3

import boto3
import requests
import os

print("🔍 Checking Group Mapping Issue\n")
print("=" * 80)

# 1. Get groups from wppconnect
print("\n1️⃣ Groups from wppconnect (WhatsApp):")
print("-" * 80)
try:
    response = requests.get('http://localhost:3005/groups', timeout=5)
    wpp_groups = response.json()
    
    for group in wpp_groups:
        name = group.get('name', '')
        gid = group.get('id', '')
        print(f"  [{name}]")
        print(f"    ID: {gid}")
        print(f"    Length: {len(name)} chars")
        print()
except Exception as e:
    print(f"  ❌ Error: {e}")

# 2. Get groups from DynamoDB WhatsAppGroups table
print("\n2️⃣ Groups from DynamoDB (WhatsAppGroups table):")
print("-" * 80)
try:
    dynamodb = boto3.resource('dynamodb', region_name=os.getenv('AWS_REGION', 'eu-west-2'))
    groups_table = dynamodb.Table(os.getenv('WHATSAPP_GROUPS_TABLE', 'WhatsAppGroups'))
    
    response = groups_table.scan()
    db_groups = response.get('Items', [])
    
    for group in db_groups:
        name = group.get('name', '')
        gid = group.get('group_id', '')
        print(f"  [{name}]")
        print(f"    group_id: {gid}")
        print(f"    Length: {len(name)} chars")
        print()
except Exception as e:
    print(f"  ❌ Error: {e}")

# 3. Get birthdays and their assigned group_ids
print("\n3️⃣ Birthdays and their group assignments:")
print("-" * 80)
try:
    birthdays_table = dynamodb.Table(os.getenv('DYNAMODB_TABLE_NAME', 'Birthdays'))
    response = birthdays_table.scan()
    birthdays = response.get('Items', [])
    
    for b in birthdays:
        name = b.get('name', '')
        gid = b.get('group_id', '')
        print(f"  {name} → group_id: {gid}")
except Exception as e:
    print(f"  ❌ Error: {e}")

# 4. Check for mismatches
print("\n4️⃣ Checking for mismatches:")
print("-" * 80)

# Find Huawei group in wppconnect
huawei_wpp = next((g for g in wpp_groups if 'Huawei' in g.get('name', '')), None)
if huawei_wpp:
    print(f"  wppconnect has: [{huawei_wpp['name']}] (ID: {huawei_wpp['id']})")

# Find Huawei group in DynamoDB
huawei_db = next((g for g in db_groups if 'Huawei' in g.get('name', '')), None)
if huawei_db:
    print(f"  DynamoDB has:   [{huawei_db['name']}] (group_id: {huawei_db['group_id']})")

if huawei_wpp and huawei_db:
    if huawei_wpp['id'] == huawei_db['group_id']:
        print("\n  ✅ IDs match!")
    else:
        print("\n  ❌ IDs DON'T match!")
        print(f"     wppconnect: {huawei_wpp['id']}")
        print(f"     DynamoDB:   {huawei_db['group_id']}")
    
    if huawei_wpp['name'] == huawei_db['name']:
        print("  ✅ Names match!")
    else:
        print("  ❌ Names DON'T match!")
        print(f"     wppconnect: [{huawei_wpp['name']}]")
        print(f"     DynamoDB:   [{huawei_db['name']}]")

print("\n" + "=" * 80)

