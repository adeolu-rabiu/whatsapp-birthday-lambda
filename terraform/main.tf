provider "aws" {
  region = var.aws_region
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# DynamoDB Tables
resource "aws_dynamodb_table" "birthdays_table" {
  name         = "Birthdays"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "birthday_id"
  range_key    = "group_id"

  attribute {
    name = "birthday_id"
    type = "S"
  }

  attribute {
    name = "group_id"
    type = "S"
  }

  attribute {
    name = "birth_month_day"
    type = "S"
  }

  global_secondary_index {
    name            = "GroupMonthDayIndex"
    hash_key        = "group_id"
    range_key       = "birth_month_day"
    projection_type = "ALL"
  }

  tags = {
    Name        = "Birthdays"
    Environment = var.environment
  }
}

resource "aws_dynamodb_table" "whatsapp_groups_table" {
  name         = "WhatsAppGroups"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "group_id"

  attribute {
    name = "group_id"
    type = "S"
  }

  tags = {
    Name        = "WhatsAppGroups"
    Environment = var.environment
  }
}

# S3 Bucket for Web UI
resource "aws_s3_bucket" "web_ui_bucket" {
  bucket = "birthday-bot-ui-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "Birthday Bot UI"
    Environment = var.environment
  }
}

# Enable website hosting
resource "aws_s3_bucket_website_configuration" "web_ui_website" {
  bucket = aws_s3_bucket.web_ui_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"  # For SPAs, route all errors back to index.html
  }
}

# Make the bucket public
resource "aws_s3_bucket_public_access_block" "web_ui_access" {
  bucket = aws_s3_bucket.web_ui_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy for public read access
resource "aws_s3_bucket_policy" "web_ui_policy" {
  bucket = aws_s3_bucket.web_ui_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.web_ui_bucket.arn}/*"
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.web_ui_access]
}

# API Gateway for frontend to backend communication
resource "aws_apigatewayv2_api" "birthday_api" {
  name          = "birthday-bot-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = [
	"http://birthday-bot-ui-${data.aws_caller_identity.current.account_id}.s3-website.eu-west-2.amazonaws.com",
	"http://localhost:3000"
	]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    allow_credentials = true
  }
}

# Default stage for API Gateway
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.birthday_api.id
  name        = "$default"
  auto_deploy = true
}

# IAM Role for Lambda execution
resource "aws_iam_role" "lambda_role" {
  name = "birthday_api_lambda_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Basic Lambda execution policy attachment
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for DynamoDB access
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "lambda_dynamodb_access"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Effect   = "Allow"
        Resource = [
          aws_dynamodb_table.birthdays_table.arn,
          aws_dynamodb_table.whatsapp_groups_table.arn
        ]
      }
    ]
  })
}

# Lambda integrations
resource "aws_apigatewayv2_integration" "birthdays_integration" {
  api_id             = aws_apigatewayv2_api.birthday_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.birthday_api_handler.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# Routes
resource "aws_apigatewayv2_route" "get_birthdays" {
  api_id    = aws_apigatewayv2_api.birthday_api.id
  route_key = "GET /birthdays"
  target    = "integrations/${aws_apigatewayv2_integration.birthdays_integration.id}"
}

resource "aws_apigatewayv2_route" "post_birthday" {
  api_id    = aws_apigatewayv2_api.birthday_api.id
  route_key = "POST /birthdays"
  target    = "integrations/${aws_apigatewayv2_integration.birthdays_integration.id}"
}

# Option routes for CORS
resource "aws_apigatewayv2_route" "options_birthdays" {
  api_id    = aws_apigatewayv2_api.birthday_api.id
  route_key = "OPTIONS /birthdays"
  target    = "integrations/${aws_apigatewayv2_integration.birthdays_integration.id}"
}

# Add the missing PUT and DELETE routes
resource "aws_apigatewayv2_route" "put_birthday" {
  api_id    = aws_apigatewayv2_api.birthday_api.id
  route_key = "PUT /birthdays/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.birthdays_integration.id}"
}

resource "aws_apigatewayv2_route" "delete_birthday" {
  api_id    = aws_apigatewayv2_api.birthday_api.id
  route_key = "DELETE /birthdays/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.birthdays_integration.id}"
}

resource "aws_apigatewayv2_route" "post_test_message" {
  api_id    = aws_apigatewayv2_api.birthday_api.id
  route_key = "POST /test-message"
  target    = "integrations/${aws_apigatewayv2_integration.birthdays_integration.id}"
}

resource "aws_apigatewayv2_route" "get_groups" {
  api_id    = aws_apigatewayv2_api.birthday_api.id
  route_key = "GET /groups"
  target    = "integrations/${aws_apigatewayv2_integration.birthdays_integration.id}"
}

resource "aws_apigatewayv2_route" "post_group" {
  api_id    = aws_apigatewayv2_api.birthday_api.id
  route_key = "POST /groups"
  target    = "integrations/${aws_apigatewayv2_integration.birthdays_integration.id}"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.birthday_api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.birthday_api.execution_arn}/*/*"
}

# Lambda for API handling 
resource "aws_lambda_function" "birthday_api_handler" {
  function_name    = "birthday-api-handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.9"
  timeout          = 30
  memory_size      = 256
  
  environment {
    variables = {
      BIRTHDAYS_TABLE = aws_dynamodb_table.birthdays_table.name
      GROUPS_TABLE    = aws_dynamodb_table.whatsapp_groups_table.name
    }
  }
  
  # For simplicity, we're using a placeholder. You'll need to create and upload the actual zip file.
  filename         = "../api_lambda.zip"
  source_code_hash = filebase64sha256("../api_lambda.zip")
}

# Update the existing Lambda role policy to include CloudWatch Metrics permissions
resource "aws_iam_role_policy" "lambda_cloudwatch" {
  name = "lambda_cloudwatch_access"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
