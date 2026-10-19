# Login and sudo. The baseline account and its authorized keys come from
# modules/nixos/users.nix.
{...}: let
  sshKeys = import ../../../lib/ssh-keys.nix;
in {
  # BigKing's uid for psoldunov, so files written to the Games share stay
  # theirs.
  users.users.psoldunov.uid = 1000;

  # The shackstack host block (modules/home/workstation/ssh.nix) logs in with
  # this key alone (IdentitiesOnly), so it has to be accepted for login too,
  # as on PiHome. That login is what loads it into the agent sudo checks.
  users.users.psoldunov.openssh.authorizedKeys.keys = [sshKeys.identities."sudo-shackstack"];

  # sudo accepts a forwarded agent holding ShackStack's own sudo key, so
  # `rebuild_system ShackStack` from Whopper needs no password. The other
  # hosts load that key by logging in with it (the shackstack entry in
  # modules/home/workstation/ssh.nix). Local sudo on the TV asks for the
  # password set with `passwd` after the install.
  environment.etc."ssh/sudo_authorized_keys" = {
    text = sshKeys.sudo.shackstack + "\n";
    mode = "0444";
  };
  security.pam.sshAgentAuth = {
    enable = true;
    authorizedKeysFiles = ["/etc/ssh/sudo_authorized_keys"];
  };
  security.pam.services.sudo.sshAgentAuth = true;
  security.sudo.extraConfig = ''
    Defaults env_keep += "SSH_AUTH_SOCK"
  '';
}
