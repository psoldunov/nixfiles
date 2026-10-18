{pkgs, ...}: {
  # Explicit autoEnable silences the upcoming-default warning; the global
  # toggle stays off so no port applies.
  catppuccin = {
    enable = false;
    autoEnable = false;
  };

  # KDE Plasma 6 desktop with SDDM as the login manager.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # XDG. The portal backends (kde, gtk, kwallet, plasmanotify) and their
  # kde-portals.conf routing come from the plasma6 module.
  xdg = {
    menus.enable = true;
    icons.enable = true;
    autostart.enable = true;
    sounds.enable = true;
    mime = {
      enable = true;
      defaultApplications = import ../mime-defaults.nix;
    };
  };

  # KDE Partition Manager (replaces GNOME Disks). The module also registers
  # kpmcore's D-Bus helper and polkit actions, which a bare package lacks.
  programs.partition-manager.enable = true;

  # KDE Connect (phone integration). The module installs kdeconnect-kde, which
  # Plasma autostarts, and opens TCP/UDP 1714-1764 for discovery and transfers.
  programs.kdeconnect.enable = true;

  # Mailspring handles mail and calendar (replaces KDE PIM). It keeps account
  # secrets in the Secret Service, which KWallet provides here (see below).
  environment.systemPackages = [pkgs.mailspring];

  # The plasma6 module turns programs.kde-pim on with mkDefault, which installs
  # Akonadi, kdepim-runtime, KMail, Kontact and Merkuro. Switch it off so none
  # of KDE PIM ships alongside Mailspring.
  programs.kde-pim.enable = false;

  # Ghostty and VS Code replace Konsole and Kate (KWrite ships with Kate).
  # ktexteditor is only listed for Kate's save-as-root helper. Without Konsole,
  # Dolphin's embedded F4 terminal panel is unavailable; "Open Terminal Here"
  # still goes to Ghostty through kdeglobals (home/desktop/plasma.nix).
  # There is no Flatpak, and apps come from Nix, so Discover goes too. The
  # plasma6 module still installs it while services.fwupd is on (it lives in
  # modules/nixos/hardware.nix); fwupdmgr covers firmware updates.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    konsole
    kate
    ktexteditor
    discover
  ];

  # X server is disabled (Wayland-only) but xkb keymap still configured
  # for TTY fallback and tools that consult it.
  services.xserver.enable = false;
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "";
  };
  services.xserver.excludePackages = [pkgs.xterm];

  # Filesystem + desktop plumbing
  # gnome-keyring is deliberately absent: KWallet from the plasma6 module is the
  # Secret Service provider, and enabling both makes pam_gnome_keyring and
  # pam_kwallet start competing daemons for org.freedesktop.secrets.
  # Thumbnails and previews come from KIO (kdegraphics-thumbnailers,
  # ffmpegthumbs), so the Nemo-era sushi/tumbler services are gone. gvfs stays
  # for GTK apps: their file dialogs use it for trash, MTP and network shares.
  services.gvfs = {
    enable = true;
    package = pkgs.gvfs;
  };
  services.udisks2.enable = true;

  programs.dconf.enable = true;
}
