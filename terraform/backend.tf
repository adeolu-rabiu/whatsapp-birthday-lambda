terraform {
  backend "s3" {
    bucket         = "whatsapp-birthday-lambda-tfstate"
    key            = "whatsapp-birthday-bot/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
