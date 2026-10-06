# Baseline psoldunov user (isNormalUser, description, shell, base groups)
# lives in modules/nixos/users.nix. BigTasty adds server-specific bits.
{...}: {
  users.users.psoldunov = {
    extraGroups = ["media"];
    linger = true;
    # BigMac's key is in modules/nixos/users.nix, shared with Whopper.
    openssh.authorizedKeys.keys = [
      # Whopper's YubiKey key (~/.ssh/git_sk).
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINUPStKGRvJ7CQqdjeOvaU/RcMvqfnXzpBoKW6CXH1aBAAAAB3NzaDpnaXQ= philipp@theswisscheese.com yubikey-19662979"
      # Whopper's old ~/.ssh/git key; drop once git_sk is in use everywhere.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBY7q/8OFggXxrXUDuqFQJgRveV2CSjuFVsGLGRCmg/g philipp@theswisscheese.com"
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
