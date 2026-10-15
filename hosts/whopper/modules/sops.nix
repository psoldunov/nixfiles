# defaultSopsFormat + age.keyFile live in modules/nixos/sops.nix.
{...}: {
  sops = {
    defaultSopsFile = ../../../secrets/whopper.yaml;

    secrets = {
      SYNCTHING_GUI_PASSWORD = {
        owner = "psoldunov";
        sopsFile = ../../../secrets/shared.yaml;
      };
      STEAM_API_KEY = {
        owner = "psoldunov";
      };
      STEAMGRIDDB_API_KEY = {
        owner = "psoldunov";
      };
      # One `access-tokens = github.com/psoldunov=<token>` line, included into
      # nix.conf (./nix.nix) so Nix can fetch private flake inputs. Owned by
      # psoldunov so unprivileged `nix flake update` reads it too; root reads
      # it anyway. BigMac includes the same one.
      NIX_ACCESS_TOKENS = {
        owner = "psoldunov";
        sopsFile = ../../../secrets/shared.yaml;
      };
    };
  };
}
