# Baseline psoldunov user (isNormalUser, description, shell, base groups)
# lives in modules/nixos/users.nix. BigTasty adds server-specific bits.
{...}: {
  users.users.psoldunov = {
    extraGroups = ["media"];
    linger = true;
    # The per-machine keys every host accepts are in modules/nixos/users.nix.
    openssh.authorizedKeys.keys = [
      # Whopper's YubiKey key (~/.ssh/git_sk), a spare: Whopper never offers
      # it on its own, since every use needs a touch.
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINUPStKGRvJ7CQqdjeOvaU/RcMvqfnXzpBoKW6CXH1aBAAAAB3NzaDpnaXQ= philipp@theswisscheese.com yubikey-19662979"
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
