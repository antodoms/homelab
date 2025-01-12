terraform {
  required_version = ">= 1.6"

  backend "s3" {}

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.4"
    }

    sops = {
      source  = "carlpett/sops"
      version = "0.7.1"
    }

    local = {
      source = "hashicorp/local"
      version = "2.5.2"
    }
  }
}

provider "kubernetes" {
  host                   = try(data.terraform_remote_state.talos-bootstrap.outputs.kubeconfig_host, "")
  cluster_ca_certificate = try(base64decode(data.terraform_remote_state.talos-bootstrap.outputs.kubeconfig_ca_certificate), "")
  client_key             = try(base64decode(data.terraform_remote_state.talos-bootstrap.outputs.kubeconfig_client_key), "")
  client_certificate     = try(base64decode(data.terraform_remote_state.talos-bootstrap.outputs.kubeconfig_client_certificate), "")
}

provider "kubectl" {
  load_config_file       = false
  host                   = try(data.terraform_remote_state.talos-bootstrap.outputs.kubeconfig_host, "")
  cluster_ca_certificate = try(base64decode(data.terraform_remote_state.talos-bootstrap.outputs.kubeconfig_ca_certificate), "")
  client_key             = try(base64decode(data.terraform_remote_state.talos-bootstrap.outputs.kubeconfig_client_key), "")
  client_certificate     = try(base64decode(data.terraform_remote_state.talos-bootstrap.outputs.kubeconfig_client_certificate), "")
}
