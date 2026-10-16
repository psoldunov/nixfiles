{pkgs, ...}: {
  # pi, the shared CLI set and the system scripts come from
  # modules/home/workstation; Whopper-only scripts from ./scripts.
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
    zoom-us
    mise
    nodejs_24
    deno
    cargo
    obsidian
    plexamp
    jellyfin-desktop
    fladder
    nocturne
    pcsx2
    duckstation
    # P.T. from the PS4 PKG; the game files and saves live in
    # ~/.local/share/pt-pc (overlays/pt-pc).
    pt-pc
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
    bambu-studio-bin
    # The ROCm build adds HIP, so Cycles renders on the 7900 XTX.
    pkgsRocm.blender
  ];
}
