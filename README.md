# WhatsApp Birthday Bot

An automated system that sends birthday wishes to WhatsApp groups using AWS Lambda, containerized with Docker, and managed through a React web interface.

## Architecture

This system runs on AWS Lambda and is triggered daily to check for birthdays. When birthdays are found, it sends messages to configured WhatsApp groups.

Key components:
- **AWS Lambda**: Serverless functions for scheduling and API endpoints
- **Docker**: Containerization for consistent deployment
- **DynamoDB**: NoSQL database for storing birthday information
- **API Gateway**: HTTP endpoints for the web interface
- **S3**: Hosting for the React web interface
- **CloudWatch**: Monitoring and logging
- **Terraform**: Infrastructure as Code for deployment

## Setup Instructions

### Prerequisites
- AWS Account
- Docker installed locally
- Node.js 14+ for web development
- Python 3.8+ for local testing
- Terraform CLI
- GitHub account

### Deployment Steps

1. **Clone the repository**

git clone https://github.com/yourusername/whatsapp-birthday-lambda.git
cd whatsapp-birthday-lambda
Copy
2. **Configure AWS credentials**
Set up your AWS credentials for Terraform:
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
Copy
3. **Initialize and apply Terraform**
cd terraform
terraform init
terraform apply
Copy
4. **Deploy the web interface**
cd ../web-ui/birthday-manager
npm install
npm run build
aws s3 sync build/ s3://birthday-bot-ui-ACCOUNT_ID
Copy
5. **Set up WhatsApp session**
Follow the instructions at `/setup` endpoint to authenticate your WhatsApp session.

## Usage

1. Access the web interface at `https://your-s3-bucket-url`
2. Add birthdays with names, dates, and custom messages
3. Configure WhatsApp groups to receive messages
4. The system will automatically send messages at 6am on birthdays

## Development

### Local Testing
cd app
python -m pytest ../tests
Copy
### Building Docker Image
cd docker
docker build -t whatsapp-birthday-bot:latest .    
-------------------------------------------------------------------------------------------------------
1. Set Up Project Structure and Version Control
2. Docker Setup with Alpine Linux
3. Lambda Function for Birthday Scheduler
4. WhatsApp Module with Selenium in Headless Mode
5. DynamoDB Data Access Layer
6. API for Managing Birthdays
7. Terraform Infrastructure as Code
8. Web UI with React
9. CI/CD Pipeline with GitHub Actions
10. Unit Tests and Integration Tests
11. CloudWatch Monitoring and Logging
12. Documentation and README
13. Deployment Script
14. Environment Variables Management
15. 15. Final Project Structure

whatsapp-birthday-lambda/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── app/
│   ├── api/
│   │   ├── __init__.py
│   │   └── handler.py
│   ├── db/
│   │   ├── __init__.py
│   │   └── dynamodb.py
│   ├── scheduler/
│   │   ├── __init__.py
│   │   └── handler.py
│   ├── whatsapp/
│   │   ├── __init__.py
│   │   └── sender.py
│   └── requirements.txt
├── config/
│   ├── dev/
│   │   └── .env
│   └── prod/
│       └── .env
├── docker/
│   └── Dockerfile
├── scripts/
│   └── deploy.sh
├── terraform/
│   ├── main.tf
│   ├── lambda.tf
│   ├── dynamodb.tf
│   ├── api_gateway.tf
│   ├── cloudwatch.tf
│   ├── variables.tf
│   └── outputs.tf
├── tests/
│   ├── integration/
│   │   └── test_api.py
│   └── unit/
│       └── test_scheduler.py
├── web-ui/
│   └── birthday-manager/
│       ├── public/
│       ├── src/
│       │   ├── components/
│       │   ├── services/
│       │   └── App.js
│       ├── package.json
│       └── README.md
└── README.md

