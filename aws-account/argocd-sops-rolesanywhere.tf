# IAM Roles Anywhere for the ArgoCD repo-server's SOPS decryption.
#
# Replaces the long-lived argocd-sops-decrypt access key. Terraform owns a
# private CA (registered here as the trust anchor); proxmox-talos copies it
# into the cluster where a cert-manager Issuer signs a short-lived client cert
# for the repo-server, which aws_signing_helper exchanges for 1h credentials.

locals {
  argocd_rolesanywhere_cn = "argocd-repo-server"
}

resource "tls_private_key" "argocd_rolesanywhere_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "argocd_rolesanywhere_ca" {
  private_key_pem = tls_private_key.argocd_rolesanywhere_ca.private_key_pem

  subject {
    common_name  = "homelab argocd rolesanywhere CA"
    organization = "homelab"
  }

  is_ca_certificate     = true
  validity_period_hours = 87600 # 10y
  # Re-issued on the first apply in its final year; the trust anchor follows.
  early_renewal_hours = 8760

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

resource "aws_rolesanywhere_trust_anchor" "argocd" {
  name    = "homelab-argocd"
  enabled = true

  source {
    source_type = "CERTIFICATE_BUNDLE"
    source_data {
      x509_certificate_data = tls_self_signed_cert.argocd_rolesanywhere_ca.cert_pem
    }
  }
}

resource "aws_iam_role" "argocd_sops" {
  name = "argocd-sops-rolesanywhere"
  path = "/homelab/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "rolesanywhere.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession", "sts:SetSourceIdentity"]
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_rolesanywhere_trust_anchor.argocd.arn
        }
        StringEquals = {
          "aws:PrincipalTag/x509Subject/CN" = local.argocd_rolesanywhere_cn
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "argocd_sops" {
  name = "argocd-sops-kms-decrypt"
  role = aws_iam_role.argocd_sops.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "kms:Decrypt"
      Resource = local.sops_kms_key_arn
    }]
  })
}

resource "aws_rolesanywhere_profile" "argocd" {
  name             = "homelab-argocd"
  enabled          = true
  role_arns        = [aws_iam_role.argocd_sops.arn]
  duration_seconds = 3600
}
