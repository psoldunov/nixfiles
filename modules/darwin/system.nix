# macOS system basics: names, the psoldunov account, login shell, sudo.
# Each host sets `networking.hostName` (hosts/<host>/modules); the other
# names and the sudo key follow from it.
{
  config,
  lib,
  pkgs,
  ...
}: let
  sshKeys = import ../../lib/ssh-keys.nix;
  hostName = config.networking.hostName;
  # BigMac -> sudo-bigmac, MacFlurry -> sudo-macflurry.
  sudoKey = sshKeys.sudo.${lib.toLower hostName};
in {
  networking = {
    computerName = hostName;
    localHostName = hostName;
  };

  # The user the homebrew module and user-level defaults act for.
  system.primaryUser = "psoldunov";

  users.users.psoldunov = {
    home = "/Users/psoldunov";
    # The same list the NixOS hosts accept (modules/nixos/users.nix).
    openssh.authorizedKeys.keys = sshKeys.authorized;
  };

  # Nixpkgs' bash crashes on macOS 27 when it restores an unset locale
  # inside a forked subshell: gettext asks CoreFoundation for the preferred
  # languages there (NixOS/nixpkgs#570561). A locale in the environment
  # skips that lookup, so every shell and nix-built script gets one.
  environment.variables.LANG = "en_US.UTF-8";

  # zsh is the login shell and fish stays installed. Both go in /etc/shells
  # and load the nix-darwin environment (PATH and friends) in every shell,
  # login or not, ssh commands included.
  programs.zsh = {
    enable = true;
    # Home Manager's ~/.zshrc runs compinit itself (modules/home/shell/zsh.nix).
    enableGlobalCompInit = false;
  };
  programs.fish.enable = true;
  environment.shells = [pkgs.zsh pkgs.fish];

  # nix-darwin only sets the login shell of users it creates, and this
  # account predates it. Pin Nix's zsh, the one Home Manager configures,
  # rather than macOS's /bin/zsh.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    loginShell="$(dscl . -read /Users/psoldunov UserShell | awk '{print $2}')"
    if [ "$loginShell" != "/run/current-system/sw/bin/zsh" ]; then
      echo "setting psoldunov's login shell to /run/current-system/sw/bin/zsh"
      dscl . -create /Users/psoldunov UserShell /run/current-system/sw/bin/zsh
    fi

    # pam_ssh_agent_auth refuses key files under a group-writable directory
    # such as /nix/store, so this is a real root-owned file, not an /etc link.
    install -m 444 -o root -g wheel ${pkgs.writeText "sudo_authorized_keys" (sudoKey + "\n")} /etc/ssh/sudo_authorized_keys
  '';

  # Touch ID for sudo at the Mac. Over SSH, where there is no sensor, sudo
  # instead accepts another workstation's forwarded agent when it holds this
  # Mac's sudo key (pam_ssh_agent_auth, built for macOS in ./overlays.nix),
  # so rebuilds from there need no password. A Mac never loads its own sudo
  # key, so local sudo still asks for Touch ID (lib/ssh-keys.nix).
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    text = lib.mkBefore "auth       sufficient     ${pkgs.pam_ssh_agent_auth}/libexec/pam_ssh_agent_auth.so file=/etc/ssh/sudo_authorized_keys";
  };
  security.sudo.extraConfig = ''
    Defaults env_keep += "SSH_AUTH_SOCK"
  '';
}
