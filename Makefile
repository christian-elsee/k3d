.DEFAULT_GOAL := all
.SHELLFLAGS := -euo pipefail $(if $(TRACE),-x,) -c
.ONESHELL:
.DELETE_ON_ERROR:

## env ##########################################
export NAME := $(shell basename $(PWD))
export PATH := dist/bin:$(PATH)

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

build:
	: ## $@

check: 
	: ## $@

## ad hoc #######################################
assets: assets.yaml
	: ## $@

	
