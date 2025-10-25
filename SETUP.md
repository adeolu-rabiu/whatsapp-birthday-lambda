# WhatsApp Birthday Bot - Setup Instructions

## Prerequisites
- Docker & Docker Compose
- AWS Account with DynamoDB access
- Node.js 18+ (for local development)
- Python 3.10+ (for local development)

## Environment Configuration

### 1. Copy environment templates
```bash
cp .env.example .env
cp dashboard/.env.example dashboard/.env
cp web-ui/birthday-manager/.env.example web-ui/birthday-manager/.env
```

### 2. Configure AWS Credentials

Edit `.env` and add your AWS credentials:
```bash
AWS_ACCESS_KEY_ID=your_actual_access_key
AWS_SECRET_ACCESS_KEY=your_actual_secret_key
AWS_REGION=eu-west-2
```

**Alternative:** Use AWS credentials file:
```bash
mkdir -p ~/.aws
cat > ~/.aws/credentials << 'CREDS'
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
CREDS
```

### 3. Update API URLs

- `web-ui/birthday-manager/.env` - Set `REACT_APP_API_URL`
- `dashboard/.env` - Set API endpoints

## Running the Application

### Start all services:
```bash
docker-compose up -d
```

### Check service status:
```bash
docker-compose ps
```

### View logs:
```bash
docker-compose logs -f
```

## Access URLs

- Web UI: http://localhost:3000
- Python API: http://localhost:5000
- WhatsApp Bot: http://localhost:3005
- Dashboard: http://localhost:8080
- Kibana: http://localhost:5601

## Security Notes

⚠️ **Never commit these files:**
- `.env`
- `.aws/credentials`
- `wppconnect-server/tokens/`
- Any file containing API keys or secrets

✅ **Safe to commit:**
- `.env.example`
- `*.env.example`
