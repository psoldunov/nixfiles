# defaultSopsFormat + age.keyFile live in modules/nixos/sops.nix.
{...}: {
  sops = {
    defaultSopsFile = ../../../secrets/whopper.yaml;

    secrets = {
      EXPRESSVPN_KEY = {
        owner = "psoldunov";
      };
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
      # Sunshine web UI login, applied before each start (./sunshine).
      SUNSHINE_WEB_PASSWORD = {
        owner = "psoldunov";
      };
    };
  };
}
