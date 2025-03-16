provider "aws" {
  region = var.aws_region
}

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
