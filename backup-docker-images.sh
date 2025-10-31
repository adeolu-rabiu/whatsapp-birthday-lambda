#!/bin/bash

echo "💾 Backing up Docker Images Locally"
echo "===================================="
echo ""

# Create backup directory
mkdir -p backups/docker-images
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="backups/docker-images/${TIMESTAMP}"
mkdir -p "${BACKUP_DIR}"

# List of services to backup
SERVICES=(
    "whatsapp-birthday-lambda_python-api"
    "whatsapp-birthday-lambda_wppconnect-bot"
    "whatsapp-birthday-lambda_web-ui"
    "whatsapp-birthday-lambda_dashboard"
    "whatsapp-birthday-lambda_cron"
)

echo "📦 Saving Docker images..."
for SERVICE in "${SERVICES[@]}"; do
    if docker images | grep -q "${SERVICE}"; then
        echo "  Saving ${SERVICE}..."
        docker save "${SERVICE}:latest" | gzip > "${BACKUP_DIR}/${SERVICE}.tar.gz"
        echo "  ✅ Saved ($(du -h ${BACKUP_DIR}/${SERVICE}.tar.gz | cut -f1))"
    else
        echo "  ⚠️  ${SERVICE} not found"
    fi
done

# Create latest symlink
rm -f backups/docker-images/latest
ln -s "${TIMESTAMP}" backups/docker-images/latest

echo ""
echo "✅ Backup complete!"
echo "Location: ${BACKUP_DIR}"
echo ""
ls -lh "${BACKUP_DIR}"

# Keep only last 3 backups
echo ""
echo "🧹 Cleaning old backups (keeping last 3)..."
cd backups/docker-images
ls -t | grep -v latest | tail -n +4 | xargs -r rm -rf
cd ../..

echo "✅ Done!"
