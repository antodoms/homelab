ONESHELL:
.SHELL := /bin/bash
.PHONY: apply output refresh apply plan prep destroy
BOLD=$(shell tput bold)
RED=$(shell tput setaf 1)
GREEN=$(shell tput setaf 2)
YELLOW=$(shell tput setaf 3)
RESET=$(shell tput sgr0)

ACCOUNT?=homelab
REGION?=ap-southeast-2
VARS="vars/$(ACCOUNT).tfvars"
BACKEND="backend/$(ACCOUNT).backend"

export TF_VAR_account=$(ACCOUNT)
export TF_VAR_aws_region=$(REGION)

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

set-env:
	@if [ ! -z $${ERROR} ] && [ $${ERROR} -eq 1 ]; then \
		echo "$(BOLD)Example usage: \`remake plan\`$(RESET)"; \
		exit 1; \
	 fi

prep: set-env ## Prepare a new workspace (environment) if needed, configure the tfstate backend, update any modules, and switch to the workspace
	@echo "$(BOLD)Configuring the Terraform backend$(RESET)"
	@echo "$(YELLOW)Backend Config Bucket:    zetech.terraform-state.$(ACCOUNT)$(RESET)"
	@rm -f .terraform/terraform.tfstate
	@rm -f .terraform/environment
	@terraform init \
		-force-copy \
		-input=false \
		-get=true \
		-upgrade \
		-reconfigure \
		-backend-config="$(BACKEND)"

refresh: prep ## Show what terraform thinks it will do
	@terraform refresh \
		-lock=true \
		-input=false \
		-var-file="$(VARS)"

plan: prep ## Show what terraform thinks it will do
	@terraform plan \
		-lock=true \
		-input=false \
		-refresh=true \
		-var-file="$(VARS)"

plan-out: prep ## Show what terraform thinks it will do
	@terraform plan \
		-lock=true \
		-input=false \
		-refresh=true \
		-var-file="$(VARS)" \
		-out=tfplan

apply: prep ## Have terraform do the things. This will apply the changes.
	@terraform apply \
		-lock=true \
		-input=false \
		-var-file="$(VARS)" \
		-refresh=true

ci-apply: prep ## Have terraform do the things. This will apply the changes.
	@terraform apply \
		-input=false \
		-refresh=true \
		-lock=true \
		-auto-approve \
		-input=false \
		tfplan

destroy: prep
	@terraform destroy \
		-lock=true \
		-input=false \
		-var-file="$(VARS)" \
		-refresh=true

encrypt:
	sops --encrypt secrets/$(ACCOUNT).yaml > secrets/$(ACCOUNT).enc.yaml

decrypt:
	sops --decrypt secrets/$(ACCOUNT).enc.yaml > secrets/$(ACCOUNT).yaml

output: prep ## Export the output values in a json file
	mkdir -p outputs/${ACCOUNT}
	@terraform output -raw talosconfig > outputs/${ACCOUNT}/talosconfig
	@terraform output -raw kubeconfig > outputs/${ACCOUNT}/kubeconfig

	@echo "$(BOLD)Kubectl examples:$(RESET)"
	@echo "$(GREEN)kubectl --kubeconfig=outputs/${ACCOUNT}/kubeconfig get nodes$(RESET)"
	@echo "$(BOLD)talosctl examples:$(RESET)"
	@echo "$(GREEN)talosctl --talosconfig=outputs/${ACCOUNT}/talosconfig config info$(RESET)"
	@echo "$(BOLD)octant examples:$(RESET)"
	@echo "$(GREEN)KUBECONFIG=outputs/${ACCOUNT}/kubeconfig octant$(RESET)"