# ShackStack's home: the shared shell, the Plasma defaults for Desktop Mode
# and its apps. A gaming box, so none of the rest of modules/home (Claude
# Code, pi, the UniFi client, sops secrets) and, of the workstation modules,
# only Ghostty.
{lib, ...}: {
  imports = [
    ../../../modules/home/shell/shell.nix
    ../../../modules/home/shell/fastfetch
    ../../../modules/home/workstation/ghostty.nix
    ./apps.nix
    ./plasma.nix
  ];

  # Keychain has no keys to load here (shell.nix lists them for desktops
  # only), and sudo runs on the agent forwarded from Whopper
  # (../modules/access.nix), which a local agent would shadow.
  programs.keychain.enable = lib.mkForce false;

  # Decky Loader drives Steam through its CEF remote debugger, which Steam
  # only opens when this file exists. Jovian leaves it to the user
  # (Jovian-NixOS#460).
  home.file.".local/share/Steam/.cef-enable-remote-debugging".text = "";

  home.stateVersion = "26.11";
}
