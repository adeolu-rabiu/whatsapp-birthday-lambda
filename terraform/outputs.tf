# Comment these out until the resources are created
# output "api_endpoint" {
#   value = aws_apigatewayv2_api.birthday_api.api_endpoint
# }

 output "web_ui_url" {
   value = "http://${aws_s3_bucket.web_ui_bucket.bucket}.s3-website-${var.aws_region}.amazonaws.com"
 }
