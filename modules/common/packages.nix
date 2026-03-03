{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cmake
    coreutils
    deno
    fd
    gh
    git-crypt
    gnused
    gnutar
    go
    jq
    mkcert
    neovim
    ripgrep
    sd
    shellcheck
    tmuxinator
    tree
    uv
    wget
    yq
    zig
    codex
  ];
}
