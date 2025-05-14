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
      "http://birthday-bot-ui-${data.aws_caller_identity.current.account_id}.s3-website.${var.aws_region}.amazonaws.com",
      "https://birthday-bot-ui-${data.aws_caller_identity.current.account_id}.s3-website.${var.aws_region}.amazonaws.com",
      "http://localhost:3000",
      "http://172.30.217.107:3000",
      "https://172.30.217.107:3000",
      "http://192.168.247.128:3000",
      "https://192.168.247.128:3000",
      "http://192.168.1.66:3000",
      "https://192.168.1.66:3000"
    ]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key", "X-Amz-Security-Token"]
    allow_credentials = true
    max_age = 300  # Cache preflight requests for 5 minutes
  }
}

# Default stage for API Gateway
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.birthday_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_function" "api_tunnel" {
  filename      = "lambda_direct/lambda_function.zip"
  function_name = "birthday_bot_api_tunnel"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.handler"  # Changed from lambda_tunnel.handler
  runtime       = "python3.10"
  timeout       = 30
  memory_size   = 256
  
  # Keep any existing environment variables, but remove references to backend URLs
  environment {
    variables = {
      AUTH_TOKEN = var.auth_token
    }
  }
  
  tags = {
    Name        = "Birthday Bot API Tunnel"
    Environment = var.environment
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name = "birthday_bot_lambda_execution_role"

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

# Basic Lambda execution policy
resource "aws_iam_policy" "lambda_basic_execution" {
  name        = "birthday_bot_lambda_basic_execution"
  description = "Allows Lambda to create logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_basic_execution.arn
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_tunnel.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.birthday_api.execution_arn}/*/*"
}

# Lambda Integration for API Gateway
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.birthday_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.api_tunnel.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# Update routes to use Lambda integration
resource "aws_apigatewayv2_route" "get_birthdays" {
  api_id    = aws_apigatewayv2_api.birthday_api.id
  route_key = "GET /birthdays"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "post_birthday" {
  api_id    = aws_apigatewayv2_api.birthday_api.id
  route_key = "POST /birthdays"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "options_birthdays" {
  api_id    = aws_apigatewayv2_api.birthday_api.id
  route_key = "OPTIONS /birthdays"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "put_birthday" {
  api_id    = aws_apigatewayv2_api.birthday_api.id
  route_key = "PUT /birthdays/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "delete_birthday" {
  api_id    = aws_apigatewayv2_api.birthday_api.id
  route_key = "DELETE /birthdays/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "post_test_message" {
  api_id    = aws_apigatewayv2_api.birthday_api.id
  route_key = "POST /test-message"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "get_groups" {
  api_id    = aws_apigatewayv2_api.birthday_api.id
  route_key = "GET /groups"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "post_group" {
  api_id    = aws_apigatewayv2_api.birthday_api.id
  route_key = "POST /groups"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Resources that were being deleted - PRESERVED FROM DELETION

# Original Lambda function handler
resource "aws_lambda_function" "birthday_api_handler" {
  filename      = "lambda_direct/lambda_function.zip"
  function_name = "birthday-api-handler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.handler"
  runtime       = "python3.9"
  timeout       = 30
  memory_size   = 256

  environment {
    variables = {
      BIRTHDAYS_TABLE = "Birthdays"
      GROUPS_TABLE    = "WhatsAppGroups"
    }
  }
}

# Original Lambda execution role
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

# Original Lambda role policies
resource "aws_iam_role_policy" "lambda_cloudwatch" {
  name = "lambda_cloudwatch_access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

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

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "birthday_lambda_logs" {
  name              = "/aws/lambda/birthday-api-handler"
  retention_in_days = 14

  tags = {
    Name        = "Birthday Bot Lambda Logs"
    Environment = var.environment
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.birthday_api.name}"
  retention_in_days = 30

  tags = {
    Environment = var.environment
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.api_tunnel.function_name}"
  retention_in_days = 30

  tags = {
    Environment = var.environment
  }
}

# IAM role for accessing DynamoDB from API 
resource "aws_iam_role" "api_dynamodb_role" {
  name = "birthday_api_dynamodb_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# Policy for DynamoDB access
resource "aws_iam_role_policy" "dynamodb_access" {
  name = "dynamodb_access_policy"
  role = aws_iam_role.api_dynamodb_role.id
  
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

# Variables are defined in variables.tf

# SNS Topic for Alerts
resource "aws_sns_topic" "birthday_alerts" {
  name = "birthday-bot-alerts"

  tags = {
    Name        = "Birthday Bot Alerts"
    Environment = var.environment
  }
}

# Email Subscription for Alerts
resource "aws_sns_topic_subscription" "admin_email" {
  topic_arn = aws_sns_topic.birthday_alerts.arn
  protocol  = "email"
  endpoint  = var.admin_email  # Use the variable you already have
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "birthday_dashboard" {
  dashboard_name = "birthday-bot-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type       = "metric"
        x          = 0
        y          = 0
        width      = 12
        height     = 6
        properties = {
          metrics = [
            [ "BirthdayBot", "BirthdaysProcessed" ],
            [ "BirthdayBot", "MessagesSent" ],
            [ "BirthdayBot", "Errors" ]
          ]
          period  = 300
          region  = var.aws_region
          title   = "Birthday Bot Metrics"
          view    = "timeSeries"
          stacked = false
        }
      },
      {
        type       = "metric"
        x          = 0
        y          = 6
        width      = 12
        height     = 6
        properties = {
          metrics = [
            [ "AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.api_tunnel.function_name ],
            [ "AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.api_tunnel.function_name ],
            [ "AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.api_tunnel.function_name ]
          ]
          period  = 300
          region  = var.aws_region
          title   = "Lambda Metrics"
          view    = "timeSeries"
          stacked = false
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "birthday-bot-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "This alarm monitors for Lambda execution errors"
  alarm_actions       = [aws_sns_topic.birthday_alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.api_tunnel.function_name
  }

  tags = {
    Name        = "Birthday Bot Lambda Error Alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "birthday_errors" {
  alarm_name          = "birthday-bot-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "BirthdayBot"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "This alarm monitors for errors in the Birthday Bot"
  alarm_actions       = [aws_sns_topic.birthday_alerts.arn]

  tags = {
    Name        = "Birthday Bot Error Alarm"
    Environment = var.environment
  }
}
