# macOS system basics: names, the psoldunov account, login shell, sudo.
{
  lib,
  pkgs,
  ...
}: {
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
    openssh.authorizedKeys.keys = (import ../../../lib/ssh-keys.nix).authorized;
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
  '';

  # Touch ID for sudo at the Mac. Over SSH there is no sensor, so remote
  # rebuilds (`ssh -t`) fall back to the password.
  security.pam.services.sudo_local.touchIdAuth = true;

  system.stateVersion = 7;
}
