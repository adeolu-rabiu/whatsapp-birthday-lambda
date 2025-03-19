variable "aws_region" {
  description = "AWS Region where resources will be deployed"
  default     = "eu-west-2"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  default     = "dev"
}

variable "admin_email" {
  description = "Email address for receiving alerts"
  type        = string
  default     = "ksentries395@gmail.com"  # Optional default value
}
