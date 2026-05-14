{pkgs, ...}: {
  programs.ssh = {
    enable = true;
    # Opt out of HM's legacy default SSH config (future removal). Any
    # wildcard defaults that were previously injected should be declared
    # explicitly under `matchBlocks."*"` if needed.
    enableDefaultConfig = false;

    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        identityFile = "~/.ssh/git";
        user = "git";
        addKeysToAgent = "yes";
      };

      "mynixos.com" = {
        hostname = "mynixos.com";
        identityFile = "~/.ssh/git";
        addKeysToAgent = "yes";
      };

      "gitlab.com" = {
        identityFile = "~/.ssh/git";
        addKeysToAgent = "yes";
        extraOptions = {
          PreferredAuthentications = "publickey";
        };
      };

      "thinkpad.theswisscheese.com" = {
        proxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
      };

      "bigtasty" = {
        hostname = "10.24.24.2";
        user = "psoldunov";
        identityFile = "~/.ssh/id_ed25519";
        addKeysToAgent = "yes";
      };
    };
  };
}
