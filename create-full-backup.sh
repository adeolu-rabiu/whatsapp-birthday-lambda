#!/bin/bash

echo "📦 Creating Complete Backup"
echo "==========================="
echo ""

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_ROOT="backups/${TIMESTAMP}"
mkdir -p "${BACKUP_ROOT}"/{docker-images,dynamodb,config}

# 1. Backup DynamoDB
echo "1️⃣ Backing up DynamoDB..."
aws dynamodb scan \
  --table-name Birthdays \
  --region eu-west-2 \
  --output json > "${BACKUP_ROOT}/dynamodb/birthdays.json"

aws dynamodb scan \
  --table-name WhatsAppGroups \
  --region eu-west-2 \
  --output json > "${BACKUP_ROOT}/dynamodb/whatsapp-groups.json" 2>/dev/null || echo "WhatsAppGroups not found"

echo "✅ DynamoDB backed up"

# 2. Backup Docker images
echo ""
echo "2️⃣ Backing up Docker images..."
SERVICES=(
    "whatsapp-birthday-lambda_python-api"
    "whatsapp-birthday-lambda_wppconnect-bot"
    "whatsapp-birthday-lambda_web-ui"
    "whatsapp-birthday-lambda_dashboard"
    "whatsapp-birthday-lambda_cron"
)

for SERVICE in "${SERVICES[@]}"; do
    if docker images | grep -q "${SERVICE}"; then
        echo "  Saving ${SERVICE}..."
        docker save "${SERVICE}:latest" | gzip > "${BACKUP_ROOT}/docker-images/${SERVICE}.tar.gz"
    fi
done

echo "✅ Docker images backed up"

# 3. Backup configuration
echo ""
echo "3️⃣ Backing up configuration..."
cp .env.example "${BACKUP_ROOT}/config/" 2>/dev/null || touch "${BACKUP_ROOT}/config/.env.example"
cp docker-compose.yml "${BACKUP_ROOT}/config/"
cp -r monitoring/prometheus/prometheus.yml "${BACKUP_ROOT}/config/" 2>/dev/null || echo "No prometheus config"

echo "✅ Config backed up"

# 4. Create restore script
echo ""
echo "4️⃣ Creating restore script..."
cat > "${BACKUP_ROOT}/restore.sh" << 'RESTORE'
#!/bin/bash

echo "🔄 Restoring from Backup"
echo "========================"
echo ""

# Restore DynamoDB
echo "1️⃣ Restoring DynamoDB..."
python3 << 'PYTHON'
import json
import boto3
from pathlib import Path

dynamodb = boto3.resource('dynamodb', region_name='eu-west-2')

# Restore Birthdays
print("  Restoring Birthdays table...")
with open('dynamodb/birthdays.json', 'r') as f:
    data = json.load(f)
    table = dynamodb.Table('Birthdays')
    with table.batch_writer() as batch:
        for item in data.get('Items', []):
            batch.put_item(Item=item)
print("  ✅ Birthdays restored")

# Restore WhatsAppGroups
if Path('dynamodb/whatsapp-groups.json').exists():
    print("  Restoring WhatsAppGroups table...")
    with open('dynamodb/whatsapp-groups.json', 'r') as f:
        data = json.load(f)
        table = dynamodb.Table('WhatsAppGroups')
        with table.batch_writer() as batch:
            for item in data.get('Items', []):
                batch.put_item(Item=item)
    print("  ✅ WhatsAppGroups restored")
PYTHON

# Restore Docker images
echo ""
echo "2️⃣ Restoring Docker images..."
for IMAGE in docker-images/*.tar.gz; do
    if [ -f "$IMAGE" ]; then
        echo "  Loading $(basename $IMAGE)..."
        docker load < "$IMAGE"
    fi
done

echo ""
echo "✅ Restore complete!"
echo ""
echo "Start services with:"
echo "  docker-compose up -d"
RESTORE

chmod +x "${BACKUP_ROOT}/restore.sh"

# 5. Create metadata
cat > "${BACKUP_ROOT}/metadata.json" << METADATA
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "commit": "$(git rev-parse HEAD)",
  "branch": "$(git branch --show-current)",
  "backup_includes": [
    "DynamoDB (Birthdays, WhatsAppGroups)",
    "Docker Images (5 services)",
    "Configuration files"
  ]
}
METADATA

# 6. Create archive
echo ""
echo "5️⃣ Creating archive..."
tar -czf "backups/complete-backup-${TIMESTAMP}.tar.gz" -C backups "${TIMESTAMP}"

echo ""
echo "==========================="
echo "✅ Complete Backup Created!"
echo ""
echo "Location: backups/complete-backup-${TIMESTAMP}.tar.gz"
echo "Size: $(du -h backups/complete-backup-${TIMESTAMP}.tar.gz | cut -f1)"
echo ""
echo "To restore:"
echo "  tar -xzf backups/complete-backup-${TIMESTAMP}.tar.gz"
echo "  cd backups/${TIMESTAMP}"
echo "  ./restore.sh"

# Keep only last 5 complete backups
echo ""
echo "🧹 Cleaning old backups (keeping last 5)..."
cd backups
ls -t complete-backup-*.tar.gz | tail -n +6 | xargs -r rm -f
ls -t -d */ | grep -E '^[0-9]' | tail -n +6 | xargs -r rm -rf
cd ..

echo "✅ Done!"
