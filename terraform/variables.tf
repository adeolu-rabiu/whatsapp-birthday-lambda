variable "aws_region" {
  description = "AWS Region where resources will be deployed"
  default     = "eu-west-2"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  default     = "dev"
}

