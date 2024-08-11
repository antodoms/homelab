data "sops_file" "proxmox-secret" {
  source_file = "secrets/${var.account}.enc.yaml"
}

locals {
    proxmox_url = try(data.sops_file.proxmox-secret.data["proxmox_url"], var.proxmox_api_url)
    proxmox_username = try(data.sops_file.proxmox-secret.data["proxmox_username"], var.proxmox_api_username)
    proxmox_password = try(data.sops_file.proxmox-secret.data["proxmox_password"], var.proxmox_api_password)
    proxmox_nodename = try(data.sops_file.proxmox-secret.data["proxmox_nodename"], var.proxmox_node)

    proxmox_bridge = try(data.sops_file.proxmox-secret.data["proxmox_bridge"], var.proxmox_bridge)
    proxmox_storage = try(data.sops_file.proxmox-secret.data["proxmox_storage"], var.proxmox_storage)
}