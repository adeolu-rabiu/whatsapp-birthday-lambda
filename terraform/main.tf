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
