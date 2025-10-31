# 🚨 Disaster Recovery Guide

## Quick Recovery Steps

### 1. Download Latest Disaster Recovery Package
```bash
# From GitHub Actions artifacts
# Go to: Actions → Latest successful run → Artifacts → disaster-recovery-package
```

### 2. Extract and Restore
```bash
# Extract package
tar -xzf disaster-recovery-YYYYMMDD.tar.gz
cd disaster-recovery

# Set up environment
cp .env.example .env
nano .env  # Add your credentials

# Run restore
./restore.sh
```

### 3. Manual Restore (if needed)
```bash
# Pull Docker images
docker login
docker pull YOUR_USERNAME/birthday-python-api:previous
docker pull YOUR_USERNAME/birthday-wppconnect-bot:previous
docker pull YOUR_USERNAME/birthday-web-ui:previous
docker pull YOUR_USERNAME/birthday-dashboard:previous
docker pull YOUR_USERNAME/birthday-cron:previous

# Restore DynamoDB
python3 restore-dynamodb.py

# Start services
docker-compose up -d
```

## Image Versioning

Every commit creates 3 tags:
- `latest` - Current production version
- `previous` - Last working version (rollback target)
- `YYYYMMDD-HHMMSS` - Timestamp version
- `{git-sha}` - Commit SHA version

### Rollback to Previous Version
```bash
cd /opt/whatsapp-birthday-lambda

# Update docker-compose.yml to use 'previous' tag
sed -i 's/:latest/:previous/g' docker-compose.yml

# Pull and restart
docker-compose pull
docker-compose up -d
```

### Rollback to Specific Version
```bash
# Use specific timestamp
docker pull YOUR_USERNAME/birthday-python-api:20241030-083000
docker tag YOUR_USERNAME/birthday-python-api:20241030-083000 \
           YOUR_USERNAME/birthday-python-api:latest

# Restart
docker-compose up -d
```

## DynamoDB Backup Strategy

- **Frequency**: Every commit to main
- **Retention**: 30 days in GitHub artifacts
- **Format**: JSON export
- **Tables**: Birthdays, WhatsAppGroups

### Manual Backup
```bash
# Backup Birthdays table
aws dynamodb scan \
  --table-name Birthdays \
  --region eu-west-2 \
  --output json > birthdays-backup-$(date +%Y%m%d).json

# Backup WhatsAppGroups table
aws dynamodb scan \
  --table-name WhatsAppGroups \
  --region eu-west-2 \
  --output json > groups-backup-$(date +%Y%m%d).json
```

### Manual Restore
```bash
# Restore from backup
python3 restore-dynamodb.py
```

## Complete System Recovery

### Scenario: Total System Loss

1. **Provision new VM**
```bash
   # Install Docker
   curl -fsSL https://get.docker.com | sh
```

2. **Clone repository**
```bash
   git clone https://github.com/YOUR_USERNAME/whatsapp-birthday-lambda.git
   cd whatsapp-birthday-lambda
```

3. **Download DR package**
```bash
   # From GitHub Actions artifacts
   wget https://github.com/YOUR_USERNAME/whatsapp-birthday-lambda/actions/artifacts/ARTIFACT_ID
   tar -xzf disaster-recovery-*.tar.gz
```

4. **Restore data**
```bash
   cp disaster-recovery/.env.example .env
   # Edit .env with credentials
   
   # Restore DynamoDB
   cd disaster-recovery
   python3 restore-dynamodb.py
```

5. **Start services**
```bash
   docker-compose up -d
```

## Testing Disaster Recovery
```bash
# Test monthly
./test-disaster-recovery.sh
```

## Recovery Time Objective (RTO)

- **Target RTO**: 30 minutes
- **Actual steps**:
  - Download DR package: 2 minutes
  - Provision VM (if needed): 10 minutes
  - Restore data: 5 minutes
  - Start services: 5 minutes
  - Verification: 5 minutes

## Recovery Point Objective (RPO)

- **Target RPO**: Last commit (< 1 hour typically)
- DynamoDB backed up on every commit to main
