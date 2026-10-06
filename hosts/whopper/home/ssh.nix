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
    # explicitly under `settings."*"` if needed.
    enableDefaultConfig = false;

    # Keys are upstream ssh_config(5) directive names.
    #
    # ~/.ssh/github is a plain ed25519 key from sops (below), so git and ssh
    # never wait for a touch. Hosts that don't know it yet fall back to the
    # older ~/.ssh/git key, which programs.keychain keeps in the agent until it
    # is retired. ~/.ssh/git_sk, the YubiKey key, is deliberately left out of
    # both the agent and this file: a FIDO2 key needs a touch for every
    # connection. It stays authorized on GitHub and Bigtasty as a spare.
    settings = {
      "github.com" = {
        HostName = "github.com";
        IdentityFile = "~/.ssh/github";
        User = "git";
        AddKeysToAgent = "yes";
      };

      "mynixos.com" = {
        HostName = "mynixos.com";
        IdentityFile = "~/.ssh/github";
        AddKeysToAgent = "yes";
      };

      "gitlab.com" = {
        IdentityFile = "~/.ssh/github";
        AddKeysToAgent = "yes";
        PreferredAuthentications = "publickey";
      };

      "thinkpad.theswisscheese.com" = {
        ProxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
      };

      "bigtasty" = {
        HostName = "10.24.24.2";
        User = "psoldunov";
        IdentityFile = "~/.ssh/github";
        ForwardAgent = true;
      };
    };
  };

  # Private keys kept in secrets/whopper.yaml. The sops-nix user service
  # decrypts them into $XDG_RUNTIME_DIR at login and links them here,
  # replacing any plain file at the same path. The .pub files stay as they are.
  sops.secrets = {
    SSH_KEY_GITHUB.path = "${config.home.homeDirectory}/.ssh/github";
    SSH_KEY_ID_ED25519.path = "${config.home.homeDirectory}/.ssh/id_ed25519";
    SSH_KEY_AGENCY_VPS.path = "${config.home.homeDirectory}/.ssh/agency-vps";
  };

  # Home Manager links ~/.ssh/config into the store, where the file belongs to
  # root. An unprivileged bubblewrap sandbox — every FHS app nixpkgs wraps,
  # Steam among them — maps our own uid and nothing else, so every
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
