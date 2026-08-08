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
