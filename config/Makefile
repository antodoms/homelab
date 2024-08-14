ONESHELL:
.SHELL := /bin/bash
.PHONY: encrypt decrypt

ACCOUNT?=homelab

encrypt:
	sops --encrypt secrets/$(ACCOUNT).yaml > secrets/$(ACCOUNT).enc.yaml

decrypt:
	sops --decrypt secrets/$(ACCOUNT).enc.yaml > secrets/$(ACCOUNT).yaml