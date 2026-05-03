locals {
    workers_with_address_and_hostname = [for nodes in local.worker_nodes: {
        address = nodes["address"],
        hostname = nodes["hostname"]
    }]
    argocd_bootstrap_app = {
    addons = templatefile("${path.module}/bootstrap/addons.yaml", {
      ingress_domain    = local.ingress_domain
      cluster_lb_ip_range = local.cluster_lb_ip_range

      argo_repository_secrets = local.argo_repository_secrets
      argo_repositories = local.argo_repositories

      worker_nodes = local.workers_with_address_and_hostname
      nfs_server_ip = local.nfs_server_ip
      media_server_nfs_path = local.media_server_nfs_path
    })

    project = templatefile("${path.module}/bootstrap/argo-project.yaml", {
      account     = var.account
    })
  }
}

resource "kubectl_manifest" "bootstrap" {
  for_each = local.argocd_bootstrap_app

  yaml_body = each.value

  depends_on = [
    talos_machine_bootstrap.this,
    talos_cluster_kubeconfig.this
  ]
}