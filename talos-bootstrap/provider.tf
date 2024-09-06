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

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.4"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.15.0"
    }

    sops = {
      source  = "carlpett/sops"
      version = "0.7.1"
    }

    tls = {
      source = "hashicorp/tls"
      version = "4.0.5"
    }
  }
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
