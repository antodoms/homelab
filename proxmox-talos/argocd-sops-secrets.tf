data "terraform_remote_state" "aws_account" {
  backend = "s3"

  config = {
    bucket = "zetech.terraform-state.homelab"
    key    = "foundational/account/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

resource "kubernetes_secret_v1" "argocd_aws_credentials" {
  metadata {
    name      = "argocd-aws-credentials"
    namespace = "argocd"
  }

  data = {
    aws_access_key_id     = data.terraform_remote_state.aws_account.outputs.argocd_sops_access_key_id
    aws_secret_access_key = data.terraform_remote_state.aws_account.outputs.argocd_sops_secret_access_key
  }

  type = "Opaque"

  depends_on = [
    talos_machine_bootstrap.this,
    talos_cluster_kubeconfig.this
  ]
}

# IAM Roles Anywhere: the CA backs the cert-manager Issuer in addons/argocd,
# and the AWS config points the repo-server's SDK at aws_signing_helper.
resource "kubernetes_secret_v1" "argocd_rolesanywhere_ca" {
  metadata {
    name      = "argocd-rolesanywhere-ca"
    namespace = "argocd"
  }

  data = {
    "tls.crt" = data.terraform_remote_state.aws_account.outputs.argocd_rolesanywhere_ca_cert_pem
    "tls.key" = data.terraform_remote_state.aws_account.outputs.argocd_rolesanywhere_ca_key_pem
  }

  type = "kubernetes.io/tls"

  depends_on = [
    talos_machine_bootstrap.this,
    talos_cluster_kubeconfig.this
  ]
}

resource "kubernetes_config_map_v1" "argocd_aws_config" {
  metadata {
    name      = "argocd-aws-config"
    namespace = "argocd"
  }

  data = {
    config = <<-EOT
      [default]
      region = ap-southeast-2
      credential_process = /custom-tools/aws_signing_helper credential-process --certificate /rolesanywhere/tls.crt --private-key /rolesanywhere/tls.key --trust-anchor-arn ${data.terraform_remote_state.aws_account.outputs.argocd_rolesanywhere_trust_anchor_arn} --profile-arn ${data.terraform_remote_state.aws_account.outputs.argocd_rolesanywhere_profile_arn} --role-arn ${data.terraform_remote_state.aws_account.outputs.argocd_rolesanywhere_role_arn}
    EOT
  }

  depends_on = [
    talos_machine_bootstrap.this,
    talos_cluster_kubeconfig.this
  ]
}
