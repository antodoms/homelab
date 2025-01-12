variable "account" {
  type = string
}

variable "aws_region" {
  type = string
  default = "ap-southeast-2"
}

variable "kubernetes_version" {
  type = string
  default = "1.30.1"
}

variable "config_branch" {
  type = string
  default = "refs/heads/main"
}

variable "app_name" {
  type = string
  default = "controlcenter"
}

variable "app_version" {
  type = string
  default = "latest"
}