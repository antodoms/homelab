data "sops_file" "secret" {
  source_file = "../config/secrets/${var.account}.enc.yaml"
}

data "aws_s3_object" "config" {
  bucket = "zetech.terraform-state.${var.account}"
  key    = "config${var.config_branch == "refs/heads/main" ? "/" : "/${var.config_branch}/"}${var.account}.json"
}


locals {
    proxmox_url = try(data.sops_file.secret.data["proxmox_url"], var.proxmox_api_url)
    proxmox_username = try(data.sops_file.secret.data["proxmox_username"], var.proxmox_api_username)
    proxmox_password = try(data.sops_file.secret.data["proxmox_password"], var.proxmox_api_password)
    proxmox_nodename = try(data.sops_file.secret.data["proxmox_nodename"], var.proxmox_node)

    proxmox_bridge = try(data.sops_file.secret.data["proxmox_bridge"], var.proxmox_bridge)
    proxmox_storage = try(data.sops_file.secret.data["proxmox_storage"], var.proxmox_storage)

    config = jsondecode(data.aws_s3_object.config.body)
    kubernetes_version = try(local.config["kubernetes_version"], var.kubernetes_version)
    talos_version = try(local.config["talos_version"], var.talos_version)
    gateway_ip = try(local.config["gateway_ip"], var.gateway_ip)

    master_nodes = try(local.config["master_nodes"], var.master_nodes)
    worker_nodes = try(local.config["worker_nodes"], var.worker_nodes)
}