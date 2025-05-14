output "web_ui_url" {
  description = "URL of the S3-hosted web UI"
  value       = "http://${aws_s3_bucket.web_ui_bucket.bucket}.s3-website.${var.aws_region}.amazonaws.com"
}

output "api_gateway_url" {
  description = "Base URL of the API Gateway"
  value       = aws_apigatewayv2_api.birthday_api.api_endpoint
}

output "primary_api_endpoints" {
  description = "Primary API endpoints using WSL backend"
  value = {
    birthdays    = "${aws_apigatewayv2_api.birthday_api.api_endpoint}/birthdays"
    groups       = "${aws_apigatewayv2_api.birthday_api.api_endpoint}/groups"
    test_message = "${aws_apigatewayv2_api.birthday_api.api_endpoint}/test-message"
  }
}

output "failover_api_endpoints" {
  description = "Failover API endpoints using main machine backend"
  value = {
    birthdays    = "${aws_apigatewayv2_api.birthday_api.api_endpoint}/birthdays-failover"
    groups       = "${aws_apigatewayv2_api.birthday_api.api_endpoint}/groups-failover"
    test_message = "${aws_apigatewayv2_api.birthday_api.api_endpoint}/test-message-failover"
  }
}

output "dynamodb_tables" {
  description = "Names of the DynamoDB tables"
  value = {
    birthdays = aws_dynamodb_table.birthdays_table.name
    groups    = aws_dynamodb_table.whatsapp_groups_table.name
  }
}
