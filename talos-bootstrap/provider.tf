terraform {
  required_version = ">= 1.6"

  backend "s3" {}

  required_providers {
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
  }
}
