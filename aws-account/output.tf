output "github_action_role_arn" {
  value = module.oidc_github.iam_role_arn
}

output "argocd_sops_access_key_id" {
  value     = aws_iam_access_key.argocd_sops.id
  sensitive = true
}

output "argocd_sops_secret_access_key" {
  value     = aws_iam_access_key.argocd_sops.secret
  sensitive = true
}

output "argocd_rolesanywhere_trust_anchor_arn" {
  value = aws_rolesanywhere_trust_anchor.argocd.arn
}

output "argocd_rolesanywhere_profile_arn" {
  value = aws_rolesanywhere_profile.argocd.arn
}

output "argocd_rolesanywhere_role_arn" {
  value = aws_iam_role.argocd_sops.arn
}

output "argocd_rolesanywhere_ca_cert_pem" {
  value = tls_self_signed_cert.argocd_rolesanywhere_ca.cert_pem
}

output "argocd_rolesanywhere_ca_key_pem" {
  value     = tls_private_key.argocd_rolesanywhere_ca.private_key_pem
  sensitive = true
}
