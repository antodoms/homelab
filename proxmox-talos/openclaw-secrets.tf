
locals {
  openclaw_enabled = yamldecode(file("${path.module}/../chart/values.yaml"))["openclawOperator"]["enable"]
}

resource "kubernetes_namespace" "openclaw_operator_system" {
  count = local.openclaw_enabled ? 1 : 0

  metadata {
    name = "openclaw-operator-system"
  }

  depends_on = [
    talos_machine_bootstrap.this,
    data.talos_cluster_kubeconfig.this
  ]
}

resource "kubernetes_secret" "openclaw_api_keys" {
  count = local.openclaw_enabled ? 1 : 0

  metadata {
    name      = "openclaw-api-keys"
    namespace = "openclaw-operator-system"
  }

  data = {
    TELEGRAM_BOT_TOKEN   = data.sops_file.secrets.data["openclaw_telegram_bot_token"]
    ANTHROPIC_API_KEY    = data.sops_file.secrets.data["openclaw_anthropic_api_key"]
    BRAVE_SEARCH_API_KEY = data.sops_file.secrets.data["openclaw_brave_search_api_key"]
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.openclaw_operator_system]
}
