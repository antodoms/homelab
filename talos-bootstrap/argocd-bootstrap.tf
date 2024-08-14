locals {
    argocd_bootstrap_app = {
    addons = templatefile("${path.module}/bootstrap/addons.yaml", {
      ingress_domain    = local.ingress_domain
      metallb_address_pool = local.cluster_lb_ip_range
      worker_nodes = local.worker_nodes
    })

    project = templatefile("${path.module}/bootstrap/argo-project.yaml", {
      account     = var.account
    })
  }
}

resource "kubectl_manifest" "bootstrap" {
  for_each = local.argocd_bootstrap_app

  yaml_body = each.value

  depends_on = [talos_machine_configuration_apply.controller]
}