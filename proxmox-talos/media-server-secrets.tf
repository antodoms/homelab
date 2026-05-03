
locals {
    media_server_enabled = yamldecode(file("${path.module}/../chart/values.yaml"))["mediaServerOperator"]["enable"]
}

resource "random_password" "mediafusion_secret" {
  length           = 16
  special          = false
}

resource "random_password" "prowlarr_api_key" {
  length           = 32
  special          = false
}

resource "kubernetes_namespace_v1" "media-center-operator" {
  metadata {
    name = "media-server-operator"
  }

  depends_on = [
    talos_machine_bootstrap.this,
    talos_cluster_kubeconfig.this
  ]
}

resource "kubernetes_secret_v1" "prowlarr_secrets" {
  count = local.media_server_enabled ? 1 : 0
  metadata {
    name = "prowlarr-secrets"
    namespace = "media-server-operator"
  }

  data = {
    PROWLARR_API_KEY = random_password.prowlarr_api_key.result
  }

  type = "generic"

  depends_on = [ kubernetes_namespace_v1.media-center-operator ]
}

resource "kubernetes_secret_v1" "mediafusion_secrets" {
  count = local.media_server_enabled ? 1 : 0
  metadata {
    name = "mediafusion-secrets"
    namespace = "media-server-operator"
  }

  data = {
    SECRET_KEY = random_password.mediafusion_secret.result
    PREMIUMIZE_OAUTH_CLIENT_ID = data.sops_file.secrets.data["premiumize_client_id"]
    PREMIUMIZE_OAUTH_CLIENT_SECRET = data.sops_file.secrets.data["premiumize_client_secret"]
  }

  type = "generic"

  depends_on = [ kubernetes_namespace_v1.media-center-operator ]
}
