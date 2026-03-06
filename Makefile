PROFILE ?= mitkuijp
FLAKE ?= .#$(PROFILE)
BACKUP_EXT ?= backup

.DEFAULT_GOAL := help

.PHONY: help switch build check show update fmt lint pin-npm

help:
	@echo "Available targets:"
	@echo "  make switch  - Apply Home Manager config ($(FLAKE)) with *.$(BACKUP_EXT) backups"
	@echo "  make build   - Build activation package"
	@echo "  make check   - Run flake checks"
	@echo "  make fmt     - Format Nix files with alejandra"
	@echo "  make lint    - Run static Nix linters (statix + deadnix)"
	@echo "  make pin-npm PACKAGE=<name> VERSION=<version> [ATTR=<attr>] - Pin or update an npm CLI"
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

pin-npm:
	@./scripts/pin-npm-cli \
		$(if $(ATTR),--attr "$(ATTR)") \
		$(if $(PACKAGE),--package "$(PACKAGE)") \
		$(if $(VERSION),--version "$(VERSION)") \
		$(if $(PNAME),--pname "$(PNAME)") \
		$(if $(LOCK_NAME),--lock-name "$(LOCK_NAME)")

show:
	nix flake show

update:
	nix flake update
