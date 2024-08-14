variable "account" {
  type = string
}

variable "aws_region" {
  type = string
  default = "ap-southeast-2"
}

variable "proxmox_api_url" {
  type = string
  default = null
}

variable "proxmox_api_username" {
  type = string
  default = null
}

variable "proxmox_api_password" {
  type = string
  default = null
}

variable "proxmox_node" {
  type = string
  default = null
}

variable "proxmox_bridge" {
    type = string
    default = "vmbr0"
}

variable "proxmox_storage" {
    type = string
    default = "local-lvm"
}

variable "talos_version" {
  type    = string
  default = "v1.7.6"
}

variable "gateway_ip" {
  type = string
}

variable "master_nodes" {
  type = list(object({
    hostname = string
    address = string
    cpu = string
    mem = number
  }))
}

variable "worker_nodes" {
  type = list(object({
    hostname = string
    address = string
    cpu = string
    mem = number
  }))
}

variable "kubernetes_version" {
  type = string
}