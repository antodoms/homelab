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
