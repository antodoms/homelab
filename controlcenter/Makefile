##
# Makefile to help manage docker-compose services
##

.PHONY: help about args list targets services build test seed up down rebuild clean start status ps logs stop restart sh bash shell

# If you need sudo to execute docker, then udpate these aliases
#
DOCKER_COMPOSE := docker compose

# Default docker-compose file
#
COMPOSE_FILE_DEFAULT := docker-compose.yml

# Default service for docker actions
# NOTE: EDIT THIS TO AVOID WARNING/ERROR MESSAGES
#
SERVICE_DEFAULT := web

# Shell command for 'shell' target
#
shell ?= bash
SHELL_CMD := /bin/$(shell)

ME := $(realpath $(firstword $(MAKEFILE_LIST)))

# Expected to be parent folder of compose file
# Contains trailing '/'
#
PWD := $(dir $(ME))

# Default package management server domain name
#
DEPENDENCY_SERVER_DEFAULT_NAME := deps

# Default package management server domain port
#
DEPENDENCY_SERVER_DEFAULT_PORT := 8808
env       ?= dev
file      ?= 
compose_file ?= $(PWD)$(COMPOSE_FILE_DEFAULT)
service   ?= $(SERVICE_DEFAULT)
services  ?=
expose_ports ?= false

.DEFAULT_GOAL := help

##
# help
# Displays a (hopefully) useful help screen to the user
#
# NOTE: Keep 'help' as first target in case .DEFAULT_GOAL is not honored
#
help: about targets args ## This help screen
ifeq ($(SERVICE_DEFAULT),)
	$(warning WARNING: SERVICE_DEFAULT is not set. Please edit makefile)
endif

about:
	@echo
	@echo "Makefile to help manage docker-compose services"

args:
	@echo
	@echo "Target arguments:"
	@echo
	@echo "    " "file"      "\t" "Location of docker-compose file (default = './$(COMPOSE_FILE_DEFAULT)')"
	@echo "    " "service"   "\t" "Target service for docker-compose actions (defauilt = '$(SERVICE_DEFAULT)')"
	@echo "    " "services"  "\t" "Target services for docker-compose actions (defauilt = all services)"

##
# list
# Displays a list of targets, using '##' comment as target description
#
# NOTE: ONLY targets with ## comments are shown
#
list: targets ## see 'targets'
targets:  ## Lists targets
	@echo
	@echo "Make targets:"
	@echo
	@cat $(ME) | \
	sed -n -E 's/^([^.][^: ]+)\s*:(([^=#]*##\s*(.*[^[:space:]])\s*)|[^=].*)$$/    \1	\4/p' | \
	sort -u | \
	expand -t15
	@echo

##
# services
#
services: ## Lists services
	@$(DOCKER_COMPOSE) -f "$(compose_file)" ps --services

##
# build
#
build: ## Builds service images [file|service|services]
	@$(DOCKER_COMPOSE) -f "$(compose_file)" build $(services)

##
# seed
#
setup: ## initial app setup, migrate and seed
	rm -rf node_modules
	@$(DOCKER_COMPOSE) -f "$(compose_file)" run --rm --entrypoint "$(SHELL_CMD) -c" "$(service)" "bundle install"
	@$(DOCKER_COMPOSE) -f "$(compose_file)" run --rm --entrypoint "$(SHELL_CMD) -c" "$(service)" "yarn install"
	@$(DOCKER_COMPOSE) -f "$(compose_file)" run --rm --entrypoint "$(SHELL_CMD) -c" "$(service)" "rails db:create db:migrate"
	@$(DOCKER_COMPOSE) -f "$(compose_file)" run --rm --entrypoint "$(SHELL_CMD) -c" "$(service)" "rails db:seed"

##
# up
#
up: ## Starts containers (in detached mode) [file|service|services]
	@$(DOCKER_COMPOSE) -f "$(compose_file)" up --detach $(services)

##
# down
#
down: ## Removes containers (preserves images and volumes) [file]
	@$(DOCKER_COMPOSE) -f "$(compose_file)" down

##
# rebuild
#
rebuild: down build ## Stops containers (via 'down'), and rebuilds service images (via 'build')

##
# clean
#
clean: ## Removes containers, images and volumes [file]
	@$(DOCKER_COMPOSE) -f "$(compose_file)" down --volumes --rmi all

##
# start
#
start: ## Starts previously-built containers (see 'build') [file|service|services]
	@$(DOCKER_COMPOSE) -f "$(compose_file)" start $(services)

##
# test
#
rspec: test
test: ## Run rspec tests
	@$(DOCKER_COMPOSE) run --rm --service-ports --entrypoint "$(SHELL_CMD) -c" "test" "docker/bin/test.sh ${file}"
##
# ps
#
status: ps ## see 'ps'
ps:        ## Shows status of containers [file|service|services]
	@$(DOCKER_COMPOSE) -f "$(compose_file)" ps $(services)

##
# logs
#
logs:  ## Shows output of running containers (in 'follow' mode) [file|service|services]
	@$(DOCKER_COMPOSE) -f "$(compose_file)" logs --follow $(services) --since 1m

##
# stop
#
stop: ## Stops containers (without removing them) [file|service|services]
	@$(DOCKER_COMPOSE) -f "$(compose_file)" stop $(services)

##
# restart
#
restart: stop start ## Stops containers (via 'stop'), and starts them again (via 'start')

##
# run
#
run: ## Run cms or auth service in ttyl mode
	@$(DOCKER_COMPOSE) -f "$(compose_file)" run --rm --service-ports "$(service)"

##
# shell
#
shell:       ## Brings up a shell in default (or specified) service [service]
ifeq ($(service),)
	$(error ERROR: 'service' is not set. Please provide 'service=' argument or edit makefile and set SERVICE_DEFAULT)
endif
	@echo
	@echo "Starting shell ($(SHELL_CMD)) in service '$(service)'"
ifeq ($(expose_ports),true)
	@$(DOCKER_COMPOSE) -f "$(compose_file)" run --rm --service-ports --entrypoint "$(SHELL_CMD)" "$(service)"
else
	@$(DOCKER_COMPOSE) -f "$(compose_file)" run --rm --entrypoint "$(SHELL_CMD)" "$(service)"
endif

##
# ssh
#
ssh:
ifeq ($(service),)
	$(error ERROR: 'service' is not set. Please provide 'service=' argument or edit makefile and set SERVICE_DEFAULT)
endif
	@echo
	@echo "Starting shell ($(SHELL_CMD)) in service '$(service)'"
	@$(DOCKER_COMPOSE) -f "$(compose_file)" exec "$(service)" "$(SHELL_CMD)"