#!/bin/bash

echo "⏰ Setting up automatic backups"
echo "================================"

# Add to crontab (daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * cd /opt/whatsapp-birthday-lambda && ./create-full-backup.sh >> logs/backup.log 2>&1") | crontab -

echo "✅ Backup cron job added"
echo ""
echo "Backups will run daily at 2:00 AM"
echo ""
echo "View backup logs:"
echo "  tail -f logs/backup.log"
