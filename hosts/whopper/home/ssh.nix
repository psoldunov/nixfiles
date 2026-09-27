{
  config,
  lib,
  pkgs,
  ...
}: {
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
        forwardAgent = true;
      };
    };
  };

  # Home Manager links ~/.ssh/config into the store, where the file belongs to
  # root. An unprivileged bubblewrap sandbox — every FHS app nixpkgs wraps,
  # Ensemblr and Steam among them — maps our own uid and nothing else, so every
  # root-owned file inside it reads as the overflow uid, `nobody`. ssh accepts
  # its config only from root or from us, so inside those sandboxes it aborts
  # with "Bad owner or permissions on ~/.ssh/config" and git and gh cannot
  # reach any host. So the generated config is installed as an ordinary file,
  # ours, 0600, which reads correctly inside a sandbox and out.
  home.file.".ssh/config".enable = false;

  home.activation.sshConfigCopy = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # A leftover link from an earlier generation would otherwise send the
    # install(1) write through to the read-only store path.
    run rm -f ${config.home.homeDirectory}/.ssh/config
    run install -Dm600 ${config.home.file.".ssh/config".source} \
      ${config.home.homeDirectory}/.ssh/config
  '';
}
