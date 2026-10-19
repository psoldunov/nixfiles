# Desktop Mode: the Plasma 6 session Steam's "Switch to Desktop" opens
# (jovian.steam.desktopSession in ./game-mode.nix). Kept lean: a browser,
# Telegram and 1Password. The Plasma settings live in ../home/plasma.nix.
{pkgs, ...}: {
  services.desktopManager.plasma6.enable = true;

  # Vapor, SteamOS's own Plasma theme, so Desktop Mode looks like the Steam
  # Deck's (selected in ../home/plasma.nix).
  nixpkgs.overlays = [(import ../../../overlays/vapor-kde.nix)];

  programs = {
    firefox.enable = true;
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = ["psoldunov"];
    };
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
