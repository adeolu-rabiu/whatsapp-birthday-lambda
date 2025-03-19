# CloudWatch Logs Group for Lambda function
resource "aws_cloudwatch_log_group" "birthday_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.birthday_api_handler.function_name}"
  retention_in_days = 14

  tags = {
    Name        = "Birthday Bot Lambda Logs"
    Environment = var.environment
  }
}

# SNS Topic for alerts
resource "aws_sns_topic" "birthday_alerts" {
  name = "birthday-bot-alerts"
  
  tags = {
    Name        = "Birthday Bot Alerts"
    Environment = var.environment
  }
}

# SNS Topic Subscription for admin email
resource "aws_sns_topic_subscription" "admin_email" {
  topic_arn = aws_sns_topic.birthday_alerts.arn
  protocol  = "email"
  endpoint  = var.admin_email
}

# CloudWatch Alarm for Error count
resource "aws_cloudwatch_metric_alarm" "birthday_errors" {
  alarm_name          = "birthday-bot-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "BirthdayBot"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This alarm monitors for errors in the Birthday Bot"
  alarm_actions       = [aws_sns_topic.birthday_alerts.arn]
  
  tags = {
    Name        = "Birthday Bot Error Alarm"
    Environment = var.environment
  }
}

# CloudWatch Alarm for Lambda execution failures
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "birthday-bot-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  dimensions = {
    FunctionName = aws_lambda_function.birthday_api_handler.function_name
  }
  alarm_description = "This alarm monitors for Lambda execution errors"
  alarm_actions     = [aws_sns_topic.birthday_alerts.arn]
  
  tags = {
    Name        = "Birthday Bot Lambda Error Alarm"
    Environment = var.environment
  }
}

# CloudWatch Dashboard for Birthday Bot metrics
resource "aws_cloudwatch_dashboard" "birthday_dashboard" {
  dashboard_name = "birthday-bot-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["BirthdayBot", "BirthdaysProcessed"],
            ["BirthdayBot", "MessagesSent"],
            ["BirthdayBot", "Errors"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Birthday Bot Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.birthday_api_handler.function_name],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.birthday_api_handler.function_name],
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.birthday_api_handler.function_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Metrics"
          period  = 300
        }
      }
    ]
  })
}
