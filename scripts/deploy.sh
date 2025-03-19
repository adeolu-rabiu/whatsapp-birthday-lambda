#!/bin/bash

# Exit on error
set -e

echo "Deploying WhatsApp Birthday Bot..."

# 1. Check prerequisites
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo "Terraform is not installed. Please install it first."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install it first."
    exit 1
fi

# 2. Configure AWS
echo "Configuring AWS..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
AWS_REGION=$(aws configure get region)
if [ -z "$AWS_REGION" ]; then
    AWS_REGION="eu-west-2"  # Default to London region
fi

# 3. Create ECR repository if it doesn't exist
echo "Setting up ECR repository..."
aws ecr describe-repositories --repository-names whatsapp-birthday-bot || \
aws ecr create-repository --repository-name whatsapp-birthday-bot

# 4. Build and push Docker image
echo "Building and pushing Docker image..."
cd docker
docker build -t whatsapp-birthday-bot:latest .
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
docker tag whatsapp-birthday-bot:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/whatsapp-birthday-bot:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/whatsapp-birthday-bot:latest
cd ..

# 5. Package Lambda functions
echo "Packaging Lambda functions..."
mkdir -p dist
cd app
pip install -r requirements.txt -t ../dist
cp -r * ../dist/
cd ..
cd dist
zip -r ../api_lambda.zip .
cd ..

# 6. Deploy infrastructure with Terraform
echo "Deploying infrastructure with Terraform..."
cd terraform
terraform init
terraform apply -auto-approve \
    -var="aws_account_id=$AWS_ACCOUNT_ID" \
    -var="aws_region=$AWS_REGION" \
    -var="admin_email=ksentries395@gmail.com"
cd ..

# 7. Deploy React app
echo "Building and deploying React app..."
cd web-ui/birthday-manager
npm install
npm run build
S3_BUCKET_NAME="birthday-bot-ui-$AWS_ACCOUNT_ID"
aws s3 sync build/ s3://$S3_BUCKET_NAME
cd ../..

# 8. Invalidate CloudFront cache if using CloudFront
if aws cloudfront list-distributions --query "DistributionList.Items[?contains(Origins.Items[].DomainName, '$S3_BUCKET_NAME')].Id" --output text &> /dev/null; then
    echo "Invalidating CloudFront cache..."
    DISTRIBUTION_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?contains(Origins.Items[].DomainName, '$S3_BUCKET_NAME')].Id" --output text)
    if [ ! -z "$DISTRIBUTION_ID" ]; then
        aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"
    fi
fi

# Correct URL format for S3 website in eu-west-2 region
echo "Deployment complete! Web UI available at: http://$S3_BUCKET_NAME.s3-website.eu-west-2.amazonaws.com"
echo ""
echo "API Gateway URL:"
API_URL=$(aws apigatewayv2 get-apis --query "Items[?Name=='birthday-bot-api'].ApiEndpoint" --output text)
echo $API_URL
