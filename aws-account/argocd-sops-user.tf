locals {
  sops_kms_key_arn = "arn:aws:kms:ap-southeast-2:780008751869:key/450e7cee-e438-434c-b268-50fc1146cd1d"
}

resource "aws_iam_user" "argocd_sops" {
  name = "argocd-sops-decrypt"
  path = "/homelab/"
}

resource "aws_iam_user_policy" "argocd_sops" {
  name = "argocd-sops-kms-decrypt"
  user = aws_iam_user.argocd_sops.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "kms:Decrypt"
      Resource = local.sops_kms_key_arn
    }]
  })
}

resource "aws_iam_access_key" "argocd_sops" {
  user = aws_iam_user.argocd_sops.name
}
