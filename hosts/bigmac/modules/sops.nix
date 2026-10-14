# System-level sops on BigMac. Only the Nix access token lives here; the
# user's secrets come through home-manager (modules/home/workstation).
{...}: {
  sops = {
    defaultSopsFile = ../../../secrets/shared.yaml;
    defaultSopsFormat = "yaml";
    age = {
      keyFile = "/Users/psoldunov/.config/sops/age/keys.txt";
      # Decrypt with the age key alone; the default would also import the
      # Mac's SSH host keys, which no secret is encrypted to.
      sshKeyPaths = [];
    };
    gnupg.sshKeyPaths = [];

    secrets = {
      # Included into nix.conf (./nix.nix). Owned by psoldunov so an
      # unprivileged `nix flake update` reads it too.
      NIX_ACCESS_TOKENS = {
        owner = "psoldunov";
      };
    };
  };
}
