.DEFAULT_GOAL := all
.SHELLFLAGS := -euo pipefail $(if $(TRACE),-x,) -c
.ONESHELL:
.DELETE_ON_ERROR:

## env ##########################################
export NAME := $(shell basename $(PWD))
export PATH := dist/bin:$(PATH)
export CLUSTER := lab1

## interface ####################################
all: distclean dist build check
install:
init: assets	

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

build:
	: ## $@


check: 
	: ## $@

install: dist/config.yaml
	: ## $@
	k3d cluster create --config $<

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
	
