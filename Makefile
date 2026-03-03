PROFILE ?= mitkuijp
FLAKE ?= .#$(PROFILE)
BACKUP_EXT ?= backup

.DEFAULT_GOAL := help

.PHONY: help switch build check show update fmt lint

help:
	@echo "Available targets:"
	@echo "  make switch  - Apply Home Manager config ($(FLAKE)) with *.$(BACKUP_EXT) backups"
	@echo "  make build   - Build activation package"
	@echo "  make check   - Run flake checks"
	@echo "  make fmt     - Format Nix files with alejandra"
	@echo "  make lint    - Run static Nix linters (statix + deadnix)"
	@echo "  make show    - Show flake outputs"
	@echo "  make update  - Update flake.lock"

switch:
	nix run . -- switch --flake $(FLAKE) -b $(BACKUP_EXT)

build:
	nix build .#homeConfigurations.$(PROFILE).activationPackage

check:
	nix flake check

fmt:
	nix run nixpkgs#alejandra -- .

lint:
	nix run nixpkgs#statix -- check .
	nix run nixpkgs#deadnix -- .

show:
	nix flake show

update:
	nix flake update
