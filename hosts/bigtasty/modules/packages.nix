{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    claude-code
    bun
    pnpm
    ghostty
    sops
    thunderbolt
    syncthing
    usbutils
    pciutils
    alejandra
    vscode
    nodejs
    ffmpeg-full
    htop
    trashy
    vdpauinfo
    libva-utils
    bat
    lm_sensors
    btop
    lsd
    mdadm
    glib
    nixd
    iperf
    distrobox-tui
    distrobox
    fzf
    libheif
    nvtopPackages.intel
    libavif
    cloudflared
    libvdpau
    imagemagick
    neovim
    wget
    yazi
    (
      pkgs.writeShellScriptBin "update_system" ''
        cd /etc/nixos
        git add .
        git commit -am "pre-update commit $(date '+%d/%m/%Y %H:%M:%S')"
        sudo nix flake update
        sudo nixos-rebuild switch --show-trace --upgrade-all
      ''
    )
    (
      pkgs.writeShellScriptBin "clean_system" ''
        sudo nix-collect-garbage -d
        nix-collect-garbage -d
        docker image prune -a -f
      ''
    )
    (
      pkgs.writeShellScriptBin "rebuild_system" ''
        cd /etc/nixos
        git add .
        git commit -am "rebuild commit $(date '+%d/%m/%Y %H:%M:%S')"
        sudo nixos-rebuild switch --show-trace
      ''
    )
    fastfetch
    (python3.withPackages (p:
      with p; [
        pygobject3
        gst-python
        numpy
        pyinotify
        pip
        mutagen
        poetry-core
        sentencepiece
      ]))
  ];
}
