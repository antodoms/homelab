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

variable "gateway_ip" {
  type = string
  default = null
}

variable "master_nodes" {
  type = list(object({
    hostname = string
    address = string
  }))
  default = null
}

variable "worker_nodes" {
  type = list(object({
    hostname = string
    address = string
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