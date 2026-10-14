# macOS system basics: names, the psoldunov account, login shell, sudo.
{
  lib,
  pkgs,
  ...
}: let
  sshKeys = import ../../../lib/ssh-keys.nix;
in {
  networking = {
    hostName = "BigMac";
    computerName = "BigMac";
    localHostName = "BigMac";
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

  # Puts fish in /etc/shells and loads the nix-darwin environment (PATH and
  # friends) in every fish, login or not, ssh commands included.
  programs.fish.enable = true;
  environment.shells = [pkgs.fish];

  # nix-darwin only sets the login shell of users it creates, and this
  # account predates it. The old login shell was Homebrew's fish, which the
  # homebrew cleanup removes, so pin the Nix one here.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    loginShell="$(dscl . -read /Users/psoldunov UserShell | awk '{print $2}')"
    if [ "$loginShell" != "/run/current-system/sw/bin/fish" ]; then
      echo "setting psoldunov's login shell to /run/current-system/sw/bin/fish"
      dscl . -create /Users/psoldunov UserShell /run/current-system/sw/bin/fish
    fi

    # pam_ssh_agent_auth refuses key files under a group-writable directory
    # such as /nix/store, so this is a real root-owned file, not an /etc link.
    install -m 444 -o root -g wheel ${pkgs.writeText "sudo_authorized_keys" (sshKeys.sudo.bigmac + "\n")} /etc/ssh/sudo_authorized_keys
  '';

  # Touch ID for sudo at the Mac. Over SSH, where there is no sensor, sudo
  # instead accepts Whopper's forwarded agent when it holds BigMac's sudo key
  # (pam_ssh_agent_auth, built for macOS in ./overlays.nix), so rebuilds from
  # Whopper need no password. BigMac never loads that key itself, so local
  # sudo still asks for Touch ID (lib/ssh-keys.nix).
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    text = lib.mkBefore "auth       sufficient     ${pkgs.pam_ssh_agent_auth}/libexec/pam_ssh_agent_auth.so file=/etc/ssh/sudo_authorized_keys";
  };
  security.sudo.extraConfig = ''
    Defaults env_keep += "SSH_AUTH_SOCK"
  '';

  system.stateVersion = 7;
}
