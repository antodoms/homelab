variable "account" {
  type = string
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
  }))
}

variable "worker_nodes" {
  type = list(object({
    hostname = string
    address = string
  }))
}

variable "kubernetes_version" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "cluster_vip" {
    type = string
}

variable "cluster_lb_ip_range" {
  type = string
}