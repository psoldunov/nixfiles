# Command-line tools every workstation gets from nixpkgs. The shared shell
# config leans on some of them (lsd and bat back the `ls` and `cat`
# aliases). Linux-only tools stay in hosts/whopper; the Macs' extras are in
# modules/home/darwin/packages.nix. Runtimes and toolchains are per host:
# Whopper takes node, bun, deno and cargo from nixpkgs, the Macs from mise
# and rustup.
{pkgs, ...}: {
  home.packages = with pkgs; [
    # Shell
    bat
    lsd
    ripgrep
    jq
    wget
    unzip
    p7zip
    tmux
    tldr
    socat
    dig
    iperf
    translate-shell

    # Charm
    glow
    gum
    pop
    skate
    soft-serve
    vhs
    wishlist

    # Nix
    alejandra
    cachix
    devenv
    nil
    nix-prefetch-scripts
    nixd
    nixpkgs-fmt

    # Secrets and keys
    age-plugin-yubikey
    infisical
    mkcert
    openssl
    sops
    yubikey-manager

    # Development
    biome
    clang-tools
    cloudflared
    cmake
    cmake-format
    cmake-lint
    dive
    glab
    go
    neovim
    php
    pkg-config
    typescript
    uv

    # Media and documents
    ffmpeg-full
    imagemagick
    libwebp
    tesseract
    woff2
  ];
}
