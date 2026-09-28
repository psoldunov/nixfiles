{
  pkgs,
  pkgs-stable,
  ...
}: {
  # NOTE: Script packages are managed by modules/home/scripts/default.nix
  # and appended to home.packages there.
  #
  # KDE-native picks: Plasma already ships Elisa (music) and KFontView (fonts),
  # so no GNOME counterparts here. KDE ISO Image Writer writes install media
  # and Tremotesf drives the Transmission daemon on BigTasty.
  home.packages = with pkgs; [
    audacity
    clockify
    ensemblr-master
    zed-editor
    pi-coding-agent
    cider-2
    ledger-live-desktop
    beets
    bruno
    yaak
    legcord
    shortwave
    qFlipper
    geekbench
    deno
    biome
    neovim
    zoom-us
    infisical
    mise
    nodejs_24
    playwright
    pkgs-stable.obsidian
    mattermost-desktop
    lmstudio
    plexamp
    pcsx2
    heroic
    bchunk
    lutris
    shipments
    ferdium
    steam-rom-manager
    kdePackages.isoimagewriter
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
    gnome-solanum
    ookla-speedtest
    motrix
    tremotesf
    uv
  ];
}
