PROFILE ?= mitkuijp
FLAKE ?= .#$(PROFILE)
BACKUP_EXT ?= backup

.DEFAULT_GOAL := help

.PHONY: help switch build check show update

help:
	@echo "Available targets:"
	@echo "  make switch  - Apply Home Manager config ($(FLAKE)) with *.$(BACKUP_EXT) backups"
	@echo "  make build   - Build activation package"
	@echo "  make check   - Run flake checks"
	@echo "  make show    - Show flake outputs"
	@echo "  make update  - Update flake.lock"

switch:
	nix run . -- switch --flake $(FLAKE) -b $(BACKUP_EXT)

build:
	nix build .#homeConfigurations.$(PROFILE).activationPackage

check:
	nix flake check

show:
	nix flake show

update:
	nix flake update
