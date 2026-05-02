module "oidc_github" {
  source  = "unfunco/oidc-github/aws"
  version = "3.0.0"

  attach_admin_policy = true
  iam_role_name       = "github-action"
  github_repositories = var.allowed_repositories
}