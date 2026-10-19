# Desktop Mode: the Plasma 6 session Steam's "Switch to Desktop" opens
# (jovian.steam.desktopSession in ./game-mode.nix). Kept lean: Firefox,
# Telegram and 1Password here, the apps in ../home/apps.nix. The Plasma
# settings live in ../home/plasma.nix.
{pkgs, ...}: {
  services.desktopManager.plasma6.enable = true;

  # The plasma6 module turns programs.kde-pim on with mkDefault, which
  # installs Akonadi, KMail, Kontact and Merkuro. Nothing here reads mail or
  # calendars.
  programs.kde-pim.enable = false;

  # Ghostty and VS Code (../home) replace Konsole and Kate, as on Whopper;
  # ktexteditor is only listed for Kate's save-as-root helper. Apps come from
  # Nix, so Discover goes too.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    konsole
    kate
    ktexteditor
    discover
  ];

  # Ghostty's font (modules/home/workstation/ghostty.nix).
  fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];

  nixpkgs.overlays = [
    # Vapor, SteamOS's own Plasma theme, so Desktop Mode looks like the Steam
    # Deck's (selected in ../home/plasma.nix).
    (import ../../../overlays/vapor-kde.nix)
    # DuckStation and P.T. for ../home/apps.nix; nixpkgs has neither.
    (import ../../../overlays/duckstation)
    (import ../../../overlays/pt-pc)
  ];

  programs = {
    firefox.enable = true;
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = ["psoldunov"];
    };
  };

  # 1Password's desktop app only talks to browser extensions it knows; Zen
  # (modules/home/programs/zen.nix) is not one of them.
  environment.etc."1password/custom_allowed_browsers" = {
    text = ''
      zen
    '';
    mode = "0755";
  };

  environment.systemPackages = [
    pkgs.telegram-desktop
    pkgs.vapor-kde-theme
    # The way back from Desktop Mode, pinned to the panel in
    # ../home/plasma.nix. steamosctl asks steamos-manager to end the Plasma
    # session and log back into Gaming Mode.
    (pkgs.makeDesktopItem {
      name = "return-to-gaming-mode";
      desktopName = "Return to Gaming Mode";
      exec = "${pkgs.jovianPackages.steamos-manager}/bin/steamosctl switch-to-game-mode";
      icon = "steam";
      categories = ["Game"];
    })
  ];
}
