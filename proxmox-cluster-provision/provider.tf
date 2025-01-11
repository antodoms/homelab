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

    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.1-rc3"
    }
  }
}


provider "aws" {
  region = var.aws_region
}

provider "proxmox" {
    pm_api_url = local.proxmox_url
    pm_user = local.proxmox_username
    pm_password = local.proxmox_password
    pm_tls_insecure = true
}