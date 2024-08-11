terraform {
  required_version = ">= 1.6"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.27.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}