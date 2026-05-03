module "oidc_github" {
  source  = "unfunco/oidc-github/aws"
  version = "3.0.0"

  dangerously_attach_admin_policy = true
  iam_role_name                   = "github-action"
  github_subjects                 = var.allowed_repositories
}