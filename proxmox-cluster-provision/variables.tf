variable "account" {
  type = string
}

variable "talos_version" {
  type    = string
  default = "v1.7.6"
}

variable "kubernetes_version" {
  type = string
  default = "1.30.1"
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

variable "proxmox_local_storage" {
    type = string
    default = "local-lvm"
}

variable "proxmox_external_storage" {
    type = string
    default = "asustorNAS"
}

variable "gateway_ip" {
  type = string
  default = null
}

variable "master_nodes" {
  type = list(object({
    hostname = string
    address = string
    cpu = string
    mem = number
  }))
  default = null
}

variable "worker_nodes" {
  type = list(object({
    hostname = string
    address = string
    cpu = string
    mem = number
  }))
  default = null
}

variable "cluster_endpoint" {
  type = string
  default = null
}

variable "cluster_vip" {
  type = string
  default = null
}

variable "cluster_lb_ip_range" {
  type = string
  default = null
}

variable "config_branch" {
  type = string
  default = "refs/heads/main"
}