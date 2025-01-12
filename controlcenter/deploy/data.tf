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

data "local_file" "config_file" {
  filename = "../../config/vars/${var.account}.json"
}

locals {
  config = jsondecode(data.local_file.config_file.content)
}