locals {
    ingress_domain = local.config["ingress_domain"]
    app_namespace = var.app_name
    app_secret_name = "${var.app_name}-secret"

    bootstrap_app = {
        application = templatefile("${path.module}/bootstrap/application.yaml", {
            app_name = var.app_name
            app_namespace = local.app_namespace
            version = var.app_version
            app_secret_name = local.app_secret_name
            ingress_domain = local.ingress_domain
        })
    }
}

resource "kubernetes_namespace" "default" {
  metadata {
    annotations = {
      name = local.app_namespace
    }
    name = local.app_namespace
  }
}

resource "kubectl_manifest" "bootstrap" {
  for_each = local.bootstrap_app

  yaml_body = each.value

  depends_on = [kubernetes_namespace.default]
}

resource "kubernetes_secret" "default" {
  metadata {
    name = local.app_secret_name
    namespace = local.app_namespace
  }

  data = data.sops_file.secrets.data

  type = "Opaque"

  depends_on = [kubernetes_namespace.default]
}