variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-2"
}

variable "auth_token" {
  description = "Authentication token for the API"
  type        = string
  sensitive   = true
  # No default - must be supplied via terraform.tfvars or environment variables
}

variable "admin_email" {
  type        = string
  description = "Admin email for SNS notifications"
}
