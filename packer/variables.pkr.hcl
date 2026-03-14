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
  # image = "https://github.com/talos-systems/talos/releases/download/${var.talos_version}/nocloud-amd64.raw.xz"
  
  # generate raw.xz image from https://factory.talos.dev/
  # select cloud  provider option and then select nocloud-amd64.raw.xz
  talos_image = "https://factory.talos.dev/image/376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba/${var.talos_version}/nocloud-amd64.raw.xz"
  ubuntu_image = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
}