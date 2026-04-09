{
  config,
  pkgs,
  lib,
  pkgs-stable,
  ...
}: {
  home.sessionVariables = {
    GOPATH = "/home/psoldunov/.go";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    DENO_INSTALL = "/home/psoldunov/.deno";
    PATH = "HOME/.local/bin:/usr/sbin:$HOME/.local/podman/bin:$HOME/.cargo/bin:$DENO_INSTALL/bin:${config.home.homeDirectory}/.bun/bin:$PATH";
    TERMINAL = "${pkgs.kitty}/bin/kitty";
    TERM = "xterm-256color";
    MAILER = "${pkgs.thunderbird}/bin/thunderbird";
    PRISMA_QUERY_ENGINE_BINARY = "${pkgs-stable.prisma-engines}/bin/query-engine";
    PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs-stable.prisma-engines}/bin/schema-engine";
    PRISMA_FMT_BINARY = "${pkgs-stable.prisma-engines}/bin/prisma-fmt";
    PRISMA_QUERY_ENGINE_LIBRARY = "${lib.getLib pkgs-stable.prisma-engines}/lib/libquery_engine.node";
  };

  programs.lazygit = {
    enable = true;
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      reload = "source ~/.config/fish/config.fish && echo 'FISH config reloaded.'";
      suspend = "systemctl suspend";
    };
    functions = {
      mkcd = {
        body = ''mkdir -p "$argv" && cd "$argv"'';
      };
      wkill = {
        body = ''hyprprop | grep '"pid":' | sed 's/[^0-9]*//g' | xargs kill'';
      };
      open = {
        body = ''xdg-open "$argv" & disown'';
      };
      fzf_kill = {
        body = ''pkill -9 $(ps aux | fzf | awk '{print $2}')'';
      };
      resetDE = {
        body = ''
          ags -q
          hyprctl reload
          ags &
        '';
      };
    };
    shellInit = ''
      set fish_greeting
    '';
    shellInitLast = ''
      source ${config.sops.secrets.SHELL_SECRETS.path}
    '';
  };

  home.shellAliases = {
    ls = "lsd -laFh";
    rm = "gio trash";
    fucking = "sudo";
    cat = "bat -p";
    thunar = "${pkgs.nemo}/bin/nemo";
    whisper = "docker exec -it whisper-rocm whisper-rocm";
  };

  programs.bash = {
    enable = true;
    enableVteIntegration = true;
    enableCompletion = true;
    bashrcExtra = "source ${config.sops.secrets.SHELL_SECRETS.path}";
  };

  programs.keychain = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    keys = [
      "git"
    ];
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
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
      nix_shell = {
        format = "[$symbol$state( \($name\))]($style) ";
        impure_msg = "";
        pure_msg = "";
      };
      custom = {
        supabase = {
          command = "${pkgs.supabase-cli}/bin/supabase -v";
          format = "via [⚡ $output](green bold) ";
          detect_folders = ["supabase"];
          ignore_timeout = true;
        };
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
  };

  programs.fastfetch = {
    enable = true;
  };
}
