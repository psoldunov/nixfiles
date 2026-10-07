{pkgs, ...}: {
  # Installs pi and, through modules/home/programs/pi, its claude-bridge
  # extension.
  programs.pi-coding-agent.enable = true;

  # NOTE: Script packages are managed by modules/home/scripts/default.nix
  # and appended to home.packages there.
  #
  # KDE-native picks: Plasma already ships Elisa (music) and KFontView (fonts),
  # so no GNOME counterparts here. KDE ISO Image Writer writes install media,
  # Filelight maps disk usage and Tremotesf drives the Transmission daemon on
  # BigTasty.
  home.packages = with pkgs; [
    audacity
    ensemblr-master
    zed-editor
    cider-2
    ledger-live-desktop
    beets
    bruno
    discord
    qFlipper
    geekbench
    deno
    biome
    neovim
    zoom-us
    infisical
    mise
    nodejs_24
    obsidian
    anytype
    plexamp
    pcsx2
    duckstation
    quiver-launcher
    heroic
    bchunk
    lutris
    shipments
    steam-rom-manager
    kdePackages.isoimagewriter
    kdePackages.filelight
    parted
    lsof
    prismlauncher
    ryubing
    picard
    telegram-desktop
    slack
    protonup-qt
    protonup-ng
    via
    ookla-speedtest
    motrix
    tremotesf
    uv
    bambu-studio-bin
  ];
}
