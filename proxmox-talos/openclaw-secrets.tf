
locals {
  openclaw_enabled = yamldecode(file("${path.module}/../chart/values.yaml"))["openclawOperator"]["enable"]
}

resource "kubernetes_namespace_v1" "openclaw_operator_system" {
  count = local.openclaw_enabled ? 1 : 0

  metadata {
    name = "openclaw-operator-system"
  }

  depends_on = [
    talos_machine_bootstrap.this,
    talos_cluster_kubeconfig.this
  ]
}

resource "kubernetes_secret_v1" "openclaw_api_keys" {
  count = local.openclaw_enabled ? 1 : 0

  metadata {
    name      = "openclaw-api-keys"
    namespace = "openclaw-operator-system"
  }

  # Extract all keys under openclaw_secrets.* from SOPS file
  data = {
    for key, value in data.sops_file.secrets.data :
    trimprefix(key, "openclaw_secrets.") => value
    if startswith(key, "openclaw_secrets.")
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace_v1.openclaw_operator_system]
}
