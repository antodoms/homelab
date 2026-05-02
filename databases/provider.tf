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
      version = "0.11.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }

    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }

    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.1-rc3"
    }

    local = {
      source = "hashicorp/local"
      version = "2.8.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.4"
    }

    tls = {
      source = "hashicorp/tls"
      version = "4.2.1"
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

provider "kubernetes" {
  host                   = try(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.host, "")
  cluster_ca_certificate = try(base64decode(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate), "")
  client_key             = try(base64decode(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key), "")
  client_certificate     = try(base64decode(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate), "")
}

provider "kubectl" {
  load_config_file       = false
  host                   = try(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.host, "")
  cluster_ca_certificate = try(base64decode(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate), "")
  client_key             = try(base64decode(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key), "")
  client_certificate     = try(base64decode(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate), "")
}