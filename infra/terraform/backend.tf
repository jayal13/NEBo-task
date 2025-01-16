terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.83.1"
    }
  }

  backend "s3" {
    bucket               = "jayal-tfstate"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "terraform-state"
    region               = "us-west-1"
    dynamodb_table       = "terraform-lock"
    profile              = "jayal"
  }
}