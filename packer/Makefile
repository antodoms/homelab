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
VARS="vars/$(ACCOUNT).pkrvars.hcl"


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
	@packer init -upgrade .

build: prep
	@packer build -only=release.proxmox.talos -var-file="$(VARS)" \
	-var proxmox_url=`sops --decrypt secrets/$(ACCOUNT).enc.yaml | yq .proxmox_url` \
	-var proxmox_username=`sops --decrypt secrets/$(ACCOUNT).enc.yaml | yq .proxmox_username` \
	-var proxmox_token=`sops --decrypt secrets/$(ACCOUNT).enc.yaml | yq .proxmox_token` \
	-var proxmox_nodename=`sops --decrypt secrets/$(ACCOUNT).enc.yaml | yq .proxmox_nodename` \
	-var proxmox_storage=`sops --decrypt secrets/$(ACCOUNT).enc.yaml | yq .proxmox_storage` \
	-var proxmox_bridge=`sops --decrypt secrets/$(ACCOUNT).enc.yaml | yq .proxmox_bridge` \
	-var iso_file_path=`sops --decrypt secrets/$(ACCOUNT).enc.yaml | yq .iso_file_path` \
	.

encrypt:
	sops --encrypt secrets/$(ACCOUNT).yaml > secrets/$(ACCOUNT).enc.yaml

decrypt:
	sops --decrypt secrets/$(ACCOUNT).enc.yaml > secrets/$(ACCOUNT).yaml