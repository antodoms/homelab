variable "account" {
  type        = string
  description = "AWS Account slug"
  default     = "homelab"
}

variable "aws_region" {
  type        = string
  description = "AWS Region to create resources in"
  default     = "ap-southeast-2"
}

variable "allowed_repositories" {
  type        = list(string)
  description = "Allowed repository with oidc authentication"
}