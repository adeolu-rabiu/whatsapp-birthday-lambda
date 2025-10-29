#!/bin/bash

echo "🔧 Fixing Missing and Mismatched Groups"
echo "========================================"
echo ""

# 1. Check current groups in DynamoDB
echo "1️⃣ Current groups in DynamoDB:"
aws dynamodb scan --table-name WhatsAppGroups --region eu-west-2 | jq -r '.Items[] | "\(.name.S) - \(.group_id.S)"'

echo ""
echo "2️⃣ Adding missing group: Rabiu's chat room"

# Add Rabiu's chat room to DynamoDB
aws dynamodb put-item \
  --table-name WhatsAppGroups \
  --region eu-west-2 \
  --item '{
    "group_id": {"S": "120363418767262845@g.us"},
    "name": {"S": "Rabiu'\''s chat room"}
  }'

echo "✅ Added Rabiu's chat room"

echo ""
echo "3️⃣ Fixing Huawei UK Alumni name (removing extra spaces)"

# First, get the current item to see what's there
current_huawei=$(aws dynamodb scan \
  --table-name WhatsAppGroups \
  --region eu-west-2 \
  --filter-expression "contains(#n, :name)" \
  --expression-attribute-names '{"#n":"name"}' \
  --expression-attribute-values '{":name":{"S":"Huawei"}}' \
  --query 'Items[0]')

echo "Current Huawei group in DynamoDB:"
echo "$current_huawei" | jq

# Update with correct name (matching WhatsApp exactly with trailing spaces)
aws dynamodb put-item \
  --table-name WhatsAppGroups \
  --region eu-west-2 \
  --item '{
    "group_id": {"S": "120363122719208363@g.us"},
    "name": {"S": "Huawei UK Alumni  "}
  }'

echo "✅ Updated Huawei UK Alumni (with trailing spaces to match WhatsApp)"

echo ""
echo "4️⃣ Verifying all groups are now in DynamoDB:"
aws dynamodb scan --table-name WhatsAppGroups --region eu-west-2 | jq -r '.Items[] | "\(.name.S) | \(.group_id.S)"' | sort

echo ""
echo "========================================"
echo "✅ Fix Complete!"


