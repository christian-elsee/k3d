.DEFAULT_GOAL := all
.SHELLFLAGS := -euo pipefail $(if $(TRACE),-x,) -c
.ONESHELL:
.DELETE_ON_ERROR:

## env ##########################################
export NAME := $(shell basename $(PWD))
export PATH := dist/bin:$(PATH)
export KUBECONFIG := dist/kubeconfig
export CLUSTER := lab1

## interface ####################################
all: distclean dist check
install:
init: assets	
clean: delete distclean

## workflow #####################################
distclean:
	: ## $@
	rm -rf dist

dist:
	: ## $@
	mkdir -p $@ $@/bin

	cp config.yaml $@
	cp -f assets/k3d_$(shell uname -s)_$(shell uname -m) $@/bin/k3d
	chmod 0500 $@/bin/*

check: config.yaml
	: ## $@
	k3d config migrate "$<" "dist/$<"

install: config.yaml
	: ## $@
	k3d cluster create \
		--config $< \
		--verbose
	<$< yq -re ".name" \
		| xargs k3d kubeconfig write \
				-o dist/kubeconfig
	kubectl cluster-info dump \
		| tee dist/cluster-info


delete: config.yaml
	: ## $@
	<$< yq -re ".name" \
		| xargs k3d cluster delete

## ad hoc #######################################
assets: assets.yaml
	: ## $@
	mkdir -p $@

	# iterate assets.yaml and install any missing assets
	<$< yq  -re 'to_entries[] | "\(.key) \(.value)"' \
		| xargs -rn2 -- sh -c 'test -f $$1 || echo $$1 $$2' _ \
		| xargs -rn2 -- sh -c '
			dirname $$1 | xargs mkdir -vp
			curl "$$2" \
				-s \
		    -L \
		    -D/dev/stderr \
				-o $$1' _

	# sanity check assets correctly installed
	<$< yq -re 'keys[]' \
		| xargs -I% -- sh -xc \
			'test -f % && stat %
			' _	
	
