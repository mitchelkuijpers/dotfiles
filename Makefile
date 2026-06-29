PROFILE ?= mitkuijp
FLAKE ?= .#$(PROFILE)
BACKUP_EXT ?= backup

.DEFAULT_GOAL := help

.PHONY: help switch build check show update fmt lint unlock lock export-key import-key

help:
	@echo "Available targets:"
	@echo "  make switch  - Apply Home Manager config ($(FLAKE)) with *.$(BACKUP_EXT) backups"
	@echo "  make build   - Build activation package"
	@echo "  make check   - Run flake checks"
	@echo "  make fmt     - Format Nix files with alejandra"
	@echo "  make lint    - Run static Nix linters (statix + deadnix)"
	@echo "  make show    - Show flake outputs"
	@echo "  make update  - Update flake.lock"
	@echo "  make unlock  - Decrypt secrets with git-crypt"
	@echo "  make lock    - Re-encrypt secrets (git-crypt lock)"
	@echo "  make export-key - Export git-crypt key as base64 for backup"
	@echo "  make import-key - Restore git-crypt key from base64 backup"

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

unlock:
	git-crypt unlock

lock:
	git-crypt lock

export-key:
	git-crypt export-key /tmp/git-crypt-key-backup
	base64 /tmp/git-crypt-key-backup > git-crypt-key-backup.b64
	@rm /tmp/git-crypt-key-backup
	@echo "Key exported to git-crypt-key-backup.b64 — store this in Bitwarden"

import-key:
	base64 -d git-crypt-key-backup.b64 > /tmp/git-crypt-key-backup
	git-crypt unlock /tmp/git-crypt-key-backup
	@rm /tmp/git-crypt-key-backup
