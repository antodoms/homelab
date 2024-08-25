
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

resource "kubernetes_secret" "prowlarr_secrets" {
  count = local.media_server_enabled ? 1 : 0
  metadata {
    name = "prowlarr-secrets"
    namespace = "media-server-operator"
  }

  data = {
    PROWLARR_API_KEY = random_password.prowlarr_api_key.result
  }

  type = "generic"
}

resource "kubernetes_secret" "mediafusion_secrets" {
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
}

# TLS

resource "tls_private_key" "default" {
  algorithm = "ECDSA"
}

resource "tls_self_signed_cert" "default" {
  private_key_pem = tls_private_key.default.private_key_pem

  # Certificate expires after 12 hours.
  validity_period_hours = 12

  # Generate a new certificate if Terraform is run within three
  # hours of the certificate's expiration time.
  early_renewal_hours = 3

  # Reasonable set of uses for a server SSL certificate.
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = ["*.${local.ingress_domain}"]

  subject {
    common_name  = local.ingress_domain
    organization = "Zetech Homelab"
  }
}

resource "kubernetes_secret" "mediaserver" {
  metadata {
    name = "default-tls-secret"
    namespace = "media-server-operator"
  }

  data = {
    "tls.crt" = tls_self_signed_cert.default.cert_pem
    "tls.key" = tls_private_key.default.private_key_pem
  }

  type = "kubernetes.io/tls"
}