# PiHome's home: the shared shell config and nothing else. The Pi is a DNS
# appliance, so it leaves out the rest of modules/home: no Claude Code, pi,
# nix-index or sops secrets (SHELL_SECRETS included).
{lib, ...}: {
  imports = [
    ../../modules/home/shell/shell.nix
  ];

  # Keychain has no keys to load here (shell.nix lists them for desktops
  # only), and sudo on the Pi runs on the forwarded agent (./default.nix).
  programs.keychain.enable = lib.mkForce false;

  home.stateVersion = "26.11";
}
