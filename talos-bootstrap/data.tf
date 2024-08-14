data "aws_s3_object" "config" {
  bucket = "zetech.terraform-state.${var.account}"
  key    = "config${var.config_branch == "refs/heads/main" ? "/" : "/${var.config_branch}/"}${var.account}.json"
}

locals {
    config = jsondecode(data.aws_s3_object.config.body)

    kubernetes_version = try(local.config["kubernetes_version"], var.kubernetes_version)
    talos_version = try(local.config["talos_version"], var.talos_version)

    gateway_ip = try(local.config["gateway_ip"], var.gateway_ip)
    cluster_endpoint = try(local.config["cluster_endpoint"], var.cluster_endpoint)
    cluster_vip = try(local.config["cluster_vip"], var.cluster_vip)
    cluster_lb_ip_range = try(local.config["cluster_lb_ip_range"], var.cluster_lb_ip_range)

    master_nodes = try(local.config["master_nodes"], var.master_nodes)
    worker_nodes = try(local.config["worker_nodes"], var.worker_nodes)
}