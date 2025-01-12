data "sops_file" "secrets" {
  source_file = "secrets/${var.account}.enc.yaml"
}

data "terraform_remote_state" "talos-bootstrap" {
  backend = "s3"

  config = {
    bucket = "zetech.terraform-state.${var.account}"
    key    = "foundational/talos-bootstrap/terraform.tfstate"
    region = "${var.aws_region}"
  }
}

data "aws_s3_object" "config" {
  bucket = "zetech.terraform-state.${var.account}"
  key    = "config${var.config_branch == "refs/heads/main" ? "/" : "/${var.config_branch}/"}${var.account}.json"
}

locals {
  config = jsondecode(data.aws_s3_object.config.body)
}