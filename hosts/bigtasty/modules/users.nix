# Baseline psoldunov user (isNormalUser, description, shell, base groups)
# lives in modules/nixos/users.nix. BigTasty adds server-specific bits.
{...}: {
  users.users.psoldunov = {
    extraGroups = ["media"];
    linger = true;
    # The keys every host accepts are in lib/ssh-keys.nix.
    openssh.authorizedKeys.keys = [
      # The YubiKey key (~/.ssh/git_sk), a spare: Whopper and BigMac never
      # offer it on their own, since every use needs a touch.
      (import ../../../lib/ssh-keys.nix).identities.git_sk
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICbbH6Z9XvEvRAQ8mvmFBTyE41eVcBMiql8CqhZny/5W Shortcuts on iPhone 15 Pro"
    ];
  };

  users.extraUsers.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };

  users.groups = {
    media = {
      gid = 1777;
      members = [];
    };
    cloudflared = {};
  };
}
