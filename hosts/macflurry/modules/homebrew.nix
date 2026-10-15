# The Homebrew apps only MacFlurry gets, on top of the shared list in
# modules/darwin/homebrew.nix (which also holds the policy). A cleanup on the
# laptop removes every cask neither list names. A laptop-only app goes here,
# not in the shared list, so BigMac doesn't pick it up.
{...}: {
  homebrew = {
    casks = [];

    # Installing these needs an App Store sign-in on the Mac.
    masApps = {
      # Tunnel home through the UniFi VPN server when away. The tunnel
      # itself (with its private key) is imported in the app, not kept here.
      "WireGuard" = 1451685025;
    };
  };
}
