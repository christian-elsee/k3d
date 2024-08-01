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
install: install/cluster dist/kubeconfig
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
	# validate configuration using migrate command
	k3d config migrate --trace "$<" \
		| tee dist/config-migrate

install/cluster: config.yaml
	: ## $@
	# create cluster
	k3d cluster create \
		--config $< \
		--verbose

dist/kubeconfig: config.yaml
	: ## $@		
	# write kubeconfig to dist
	<$< yq -re ".metadata.name" \
		| xargs k3d kubeconfig write \
				-o $@

	# sanity check against kubectl
	kubectl cluster-info \
		--request-timeout="5s" \
	| tee dist/cluster-info
	kubectl cluster-info dump \
		--request-timeout="5s" \
	| tee dist/cluster-info-dump

	# copy to "artifact ready" file postpended with md5sum hash
	<$@ md5sum \
		| cut -f1 -d" " \
		| xargs -tI% cp $@ $@.%

delete: config.yaml
	: ## $@
	<$< yq -re ".metadata.name" \
		| xargs k3d cluster delete

## ad hoc #######################################
assets: assets/.touch 
assets/.touch: assets.yaml
	: ## $@
	dirname $@ | xargs mkdir -p
	touch   $@

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
	
