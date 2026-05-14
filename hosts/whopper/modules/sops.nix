{...}: {
  sops = {
    defaultSopsFile = ../../../secrets/whopper.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/psoldunov/.config/sops/age/keys.txt";

    secrets = {
      EXPRESSVPN_KEY = {
        owner = "psoldunov";
      };
      SYNCTHING_GUI_PASSWORD = {
        owner = "psoldunov";
      };
      STEAM_API_KEY = {
        owner = "psoldunov";
      };
    };
  };
}
