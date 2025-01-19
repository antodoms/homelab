data "sops_file" "secrets" {
  source_file = "../config/secrets/${var.account}.enc.yaml"
}

data "local_file" "config_file" {
  filename = "../config/vars/${var.account}.json"
}

locals {
    proxmox_url = try(data.sops_file.secrets.data["proxmox_url"], var.proxmox_api_url)
    proxmox_username = try(data.sops_file.secrets.data["proxmox_username"], var.proxmox_api_username)
    proxmox_password = try(data.sops_file.secrets.data["proxmox_password"], var.proxmox_api_password)
    proxmox_nodename = try(data.sops_file.secrets.data["proxmox_nodename"], var.proxmox_node)

    proxmox_bridge = try(data.sops_file.secrets.data["proxmox_bridge"], var.proxmox_bridge)
    proxmox_local_storage = try(data.sops_file.secrets.data["proxmox_local_storage"], var.proxmox_local_storage)
    proxmox_external_storage = try(data.sops_file.secrets.data["proxmox_external_storage"], var.proxmox_external_storage)

    config = jsondecode(data.local_file.config_file.content)
    kubernetes_version = try(local.config["kubernetes_version"], var.kubernetes_version)
    talos_version = try(local.config["talos_version"], var.talos_version)
    
    gateway_ip = try(local.config["gateway_ip"], var.gateway_ip)
    cluster_endpoint = try(local.config["cluster_endpoint"], var.cluster_endpoint)
    cluster_vip = try(local.config["cluster_vip"], var.cluster_vip)
    cluster_lb_ip_range = try(local.config["cluster_lb_ip_range"], var.cluster_lb_ip_range)

    master_nodes = try(local.config["master_nodes"], var.master_nodes)
    worker_nodes = try(local.config["worker_nodes"], var.worker_nodes)

    nfs_server_ip = try(local.config["nfs_server"]["address"])
    media_server_nfs_path = try(local.config["nfs_server"]["media_server_path"])
}
