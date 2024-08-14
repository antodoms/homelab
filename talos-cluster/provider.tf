terraform {
  required_version = ">= 1.6"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.27.0"
    }
    # see https://registry.terraform.io/providers/siderolabs/talos
    # see https://github.com/siderolabs/terraform-provider-talos
    talos = {
      source = "siderolabs/talos"
      version = "0.5.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.14.0"
    }

    sops = {
      source  = "carlpett/sops"
      version = "0.7.1"
    }
  }
}


provider "aws" {
  region = var.aws_region
}
