# DynamoDB access policy
resource "aws_iam_policy" "dynamodb_access_lambda" {
  name        = "birthday_bot_dynamodb_access_lambda"
  description = "Allows Lambda to access DynamoDB tables"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:dynamodb:eu-west-2:897722667140:table/Birthdays",
          "arn:aws:dynamodb:eu-west-2:897722667140:table/WhatsAppGroups"
        ]
      }
    ]
  })
}

# Attach DynamoDB policy to Lambda execution role
resource "aws_iam_role_policy_attachment" "dynamodb_attachment_lambda" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.dynamodb_access_lambda.arn
}
