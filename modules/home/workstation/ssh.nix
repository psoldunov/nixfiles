# SSH on both workstations: one key set and one host list.
{
  config,
  lib,
  pkgs,
  ...
}: let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  homeDir = config.home.homeDirectory;
  sshKeys = import ../../../lib/ssh-keys.nix;
  # github -> SSH_KEY_GITHUB, agency-vps -> SSH_KEY_AGENCY_VPS
  secretName = name: "SSH_KEY_" + lib.toUpper (builtins.replaceStrings ["-"] ["_"] name);
  cloudflaredProxy = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
in {
  programs.ssh = {
    enable = true;
    # Opt out of HM's legacy default SSH config (future removal). Any
    # wildcard defaults that were previously injected should be declared
    # explicitly under `settings."*"` if needed.
    enableDefaultConfig = false;

    # OrbStack maintains this file itself. An Include only works above the
    # first Host block, which is where HM puts it.
    includes = lib.optionals isDarwin [
      "~/.orbstack/ssh/config"
    ];

    # macOS's ssh knows UseKeychain; nixpkgs' openssh would reject it.
    extraOptionOverrides = lib.optionalAttrs isDarwin {
      IgnoreUnknown = "UseKeychain";
    };

    # Keys are upstream ssh_config(5) directive names.
    #
    # ~/.ssh/github is a plain ed25519 key from sops (below), so git and ssh
    # never wait for a touch. ~/.ssh/git_sk, the YubiKey key, is deliberately
    # left out of both the agent and this file: a FIDO2 key needs a touch for
    # every connection. It stays authorized on GitHub and Bigtasty as a spare.
    settings =
      {
        "github.com" = {
          HostName = "github.com";
          IdentityFile = "~/.ssh/github";
          User = "git";
          AddKeysToAgent = "yes";
        };

        "gitlab.com" = {
          IdentityFile = "~/.ssh/github";
          AddKeysToAgent = "yes";
          PreferredAuthentications = "publickey";
        };

        "ssh.getflywheel.com" = {
          IdentityFile = "~/.ssh/flywheel";
          AddKeysToAgent = "yes";
        };

        "thinkpad.theswisscheese.com".ProxyCommand = cloudflaredProxy;
        "bigking.theswisscheese.com".ProxyCommand = cloudflaredProxy;
        "bigtasty.theswisscheese.com".ProxyCommand = cloudflaredProxy;

        "boundary-vps" = {
          HostName = "178.105.83.95";
          User = "psoldunov";
          IdentityFile = "~/.ssh/agency-vps";
        };

        "boundary-vps-root" = {
          HostName = "178.105.83.95";
          User = "root";
          IdentityFile = "~/.ssh/agency-vps";
        };

        # Forwarding the agent lets BigTasty's sudo authenticate with it
        # (pam_ssh_agent_auth), so remote rebuilds need no password.
        "bigtasty" = {
          HostName = "10.24.24.2";
          User = "psoldunov";
          IdentityFile = "~/.ssh/github";
          AddKeysToAgent = "yes";
          ForwardAgent = true;
        };

        # The NAS, set up like BigTasty.
        "bigking" = {
          HostName = "10.24.24.3";
          User = "psoldunov";
          IdentityFile = "~/.ssh/github";
          AddKeysToAgent = "yes";
          ForwardAgent = true;
        };

        # Logging in with the host's sudo key puts it in the local agent, and
        # forwarding that agent lets the host's sudo accept it, so remote
        # rebuilds need no password (lib/ssh-keys.nix). IdentitiesOnly makes
        # that login use the sudo key: otherwise ssh offers the agent's keys
        # first, the GitHub key (authorized on every host) gets in, and the
        # sudo key never reaches the agent, so a remote sudo with no terminal
        # fails.
        "bigmac" = {
          HostName = "bigmac.local";
          User = "psoldunov";
          IdentityFile = "~/.ssh/sudo-bigmac";
          IdentitiesOnly = true;
          AddKeysToAgent = "yes";
          ForwardAgent = true;
        };

        # The laptop is on Wi-Fi with a DHCP address, so it goes by mDNS.
        "macflurry" = {
          HostName = "macflurry.local";
          User = "psoldunov";
          IdentityFile = "~/.ssh/sudo-macflurry";
          IdentitiesOnly = true;
          AddKeysToAgent = "yes";
          ForwardAgent = true;
        };

        "whopper" = {
          HostName = "10.24.24.5";
          User = "psoldunov";
          IdentityFile = "~/.ssh/sudo-whopper";
          IdentitiesOnly = true;
          AddKeysToAgent = "yes";
          ForwardAgent = true;
        };
      }
      // lib.optionalAttrs isDarwin {
        # Whopper's keychain(1) preloads the agent at login. On macOS the
        # launchd agent fills itself on first use, and the Keychain holds the
        # passphrases of the keys that have one (flywheel, secrets).
        "*" = {
          AddKeysToAgent = "yes";
          UseKeychain = "yes";
        };
      };
  };

  # Private keys kept in secrets/shared.yaml. sops-nix decrypts them at login
  # (a systemd user service on Linux, a launchd agent on macOS) and links them
  # here, replacing any plain file at the same path. The public halves come
  # from lib/ssh-keys.nix.
  sops.secrets = lib.mapAttrs' (name: _:
    lib.nameValuePair (secretName name) {
      sopsFile = ../../../secrets/shared.yaml;
      path = "${homeDir}/.ssh/${name}";
    })
  sshKeys.identities;

  home.file =
    lib.mapAttrs' (name: publicKey:
      lib.nameValuePair ".ssh/${name}.pub" {text = publicKey + "\n";})
    sshKeys.identities
    // {
      # Home Manager links ~/.ssh/config into the store, where the file
      # belongs to root. An unprivileged bubblewrap sandbox — every FHS app
      # nixpkgs wraps, Steam among them — maps our own uid and nothing else,
      # so every root-owned file inside it reads as the overflow uid,
      # `nobody`. ssh accepts its config only from root or from us, so inside
      # those sandboxes it aborts with "Bad owner or permissions on
      # ~/.ssh/config" and git and gh cannot reach any host. So the generated
      # config is installed as an ordinary file, ours, 0600, which reads
      # correctly inside a sandbox and out.
      ".ssh/config".enable = false;
    };

  home.activation.sshConfigCopy = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # A leftover link from an earlier generation would otherwise send the
    # install(1) write through to the read-only store path.
    run rm -f ${homeDir}/.ssh/config
    run install -Dm600 ${config.home.file.".ssh/config".source} \
      ${homeDir}/.ssh/config
  '';
}
