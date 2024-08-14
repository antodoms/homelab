variable "proxmox_username" {
  type = string
}

variable "proxmox_password" {
  type = string
}

variable "proxmox_url" {
  type = string
}

variable "proxmox_nodename" {
  type = string
}

variable "proxmox_storage" {
  type = string
}

variable "proxmox_storage_type" {
  type = string
}

variable "proxmox_bridge" {
    type = string
}


variable "talos_version" {
  type    = string
  default = "v1.7.6"
}

variable "iso_file_path" {
    type = string
}

locals {
  image = "https://github.com/talos-systems/talos/releases/download/${var.talos_version}/nocloud-amd64.raw.xz"
}