{
  config,
  pkgs,
  lib,
  pkgs-stable,
  hostConfig,
  ...
}: let
  isDesktop = hostConfig.role == "desktop";
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  # Whopper's Plasma desktop. BigMac is a desktop too, but macOS has its own
  # terminal, mail and `open`, and no systemd.
  isLinuxDesktop = isDesktop && !isDarwin;
  homeDir = config.home.homeDirectory;
in {
  home.sessionVariables =
    {
      GOPATH = "${homeDir}/.go";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    }
    // lib.optionalAttrs isDesktop {
      DENO_INSTALL = "${homeDir}/.deno";
      PATH = "$HOME/.local/bin:/usr/sbin:$HOME/.local/podman/bin:$HOME/.cargo/bin:$DENO_INSTALL/bin:${homeDir}/.bun/bin:$PATH";
      TERM = "xterm-256color";
    }
    // lib.optionalAttrs isLinuxDesktop {
      TERMINAL = "${pkgs.ghostty}/bin/ghostty";
      MAILER = "${pkgs.mailspring}/bin/mailspring";
      PRISMA_QUERY_ENGINE_BINARY = "${pkgs-stable.prisma-engines}/bin/query-engine";
      PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs-stable.prisma-engines}/bin/schema-engine";
      PRISMA_FMT_BINARY = "${pkgs-stable.prisma-engines}/bin/prisma-fmt";
      PRISMA_QUERY_ENGINE_LIBRARY = "${lib.getLib pkgs-stable.prisma-engines}/lib/libquery_engine.node";
    };

  programs.lazygit.enable = true;

  programs.fish = {
    enable = true;
    shellAliases =
      {
        reload = "source ~/.config/fish/config.fish && echo 'FISH config reloaded.'";
      }
      // lib.optionalAttrs isDesktop {
        suspend =
          if isDarwin
          then "pmset sleepnow"
          else "systemctl suspend";
      };
    functions =
      {
        mkcd = {
          body = ''mkdir -p "$argv" && cd "$argv"'';
        };
      }
      // lib.optionalAttrs isDesktop {
        fzf_kill = {
          body = ''pkill -9 $(ps aux | fzf | awk '{print $2}')'';
        };
      }
      # macOS ships its own open(1).
      // lib.optionalAttrs isLinuxDesktop {
        open = {
          body = ''xdg-open "$argv" & disown'';
        };
      };
    shellInit = ''
      set fish_greeting
    '';
    shellInitLast = ''
      if test -r ${config.sops.secrets.SHELL_SECRETS.path}
        source ${config.sops.secrets.SHELL_SECRETS.path}
      end
    '';
  };

  home.shellAliases = {
    ls = "lsd -laFh";
    # macOS has trash(1) since 15.
    rm =
      if isDarwin
      then "trash"
      else "gio trash";
    fucking = "sudo";
    cat = "bat -p";
    c = "claude";
  };

  # macOS apps, VS Code's terminal and Claude Code's Bash tool start zsh, not
  # the login shell (fish). So on BigMac zsh gets the same setup: aliases and
  # session variables come from home.*, every HM integration here and in the
  # sibling modules (starship, zoxide, atuin, fzf, yazi, direnv, mise,
  # nix-index) follows `programs.zsh.enable`, and the secrets and MCP tokens
  # are sourced like in bash (here, ../programs/claude-code/mcp.nix and
  # ../workstation/mailspring.nix).
  programs.zsh = {
    enable = isDarwin;
    enableCompletion = true;
    initContent = ''
      [ -r ${config.sops.secrets.SHELL_SECRETS.path} ] && source ${config.sops.secrets.SHELL_SECRETS.path}
    '';
  };

  programs.bash = {
    enable = true;
    # VTE terminals (GNOME Terminal, Ptyxis and friends) are Linux-only.
    enableVteIntegration = !isDarwin;
    enableCompletion = true;
    bashrcExtra = ''
      [ -r ${config.sops.secrets.SHELL_SECRETS.path} ] && source ${config.sops.secrets.SHELL_SECRETS.path}
    '';
  };

  # On macOS the launchd ssh-agent and the Keychain do this job
  # (modules/home/workstation/ssh.nix).
  programs.keychain = {
    enable = !isDarwin;
    enableFishIntegration = true;
    enableBashIntegration = true;
    # github and agency-vps come from sops (modules/home/workstation/ssh.nix)
    # and have no passphrase, so they load without a prompt. The YubiKey key
    # git_sk is left out on purpose: anything in the agent can be offered,
    # and each use of it needs a touch.
    keys = lib.optionals isDesktop ["github" "agency-vps"];
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    # Atuin owns Ctrl-R; keep fzf off it (fzf file/dir widgets stay).
    historyWidget.command = "";
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    settings = {
      format = "$nix_shell$env_var $all";
      hostname = {
        ssh_only = true;
        disabled = false;
      };
      bun = {
        format = "via [🥟 $version](bold green) ";
      };
      nodejs = {
        detect_files = ["package.json" ".node-version" "!bunfig.toml" "!deno.lock" "!bun.lockb" "!bun.lock" "!deno.json"];
      };
      deno = {
        format = "via [🦕 $version](green bold) ";
      };
      gcloud = {
        disabled = true;
      };
      nix_shell = {
        format = "[$symbol$state( \($name\))]($style) ";
        impure_msg = "";
        pure_msg = "";
      };
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    options = [
      "--cmd j"
    ];
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
  };

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    shellWrapperName = "y";
  };

  programs.fastfetch = {
    enable = true;
  };
}
