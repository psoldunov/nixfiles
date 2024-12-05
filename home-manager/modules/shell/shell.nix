{
  config,
  pkgs,
  ...
}: {
  home.sessionVariables = {
    GOPATH = "/home/psoldunov/.go";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    DENO_INSTALL = "/home/psoldunov/.deno";
    PATH = "HOME/.local/bin:/usr/sbin:$HOME/.local/podman/bin:$HOME/.cargo/bin:$DENO_INSTALL/bin:$PATH";
    TERMINAL = "kitty";
    TERM = "xterm-256color";
    MAILER = "${pkgs.thunderbird}/bin/thunderbird";
    VSCODE_GALLERY_SERVICE_URL = "https://marketplace.visualstudio.com/_apis/public/gallery";
    VSCODE_GALLERY_ITEM_URL = "https://marketplace.visualstudio.com/items";
    VSCODE_GALLERY_CACHE_URL = "https://vscode.blob.core.windows.net/gallery/index";
    VSCODE_GALLERY_CONTROL_URL = "";
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
      # ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      set -Ua fish_user_paths $HOME/.cargo/bin
      set --export BUN_INSTALL "$HOME/.bun"
      set --export PATH $BUN_INSTALL/bin $PATH
      set fish_greeting
    '';
    shellInitLast = "source ${config.sops.secrets.SHELL_SECRETS.path}";
  };

  home.shellAliases = {
    ls = "lsd -laFh";
    rm = "gio trash";
    fucking = "sudo";
    cat = "bat -p";
    thunar = "nemo";
    ssh = "kitten ssh";
    # ollama = "docker exec -it ollama ollama";
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
    enableNushellIntegration = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    keys = [
      "git"
    ];
  };

  programs.nushell = {
    enable = true;
    # extraConfig = "source ${config.sops.secrets.SHELL_SECRETS.path}";
  };

  programs.thefuck = {
    enable = true;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
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
        detect_files = ["package.json" ".node-version" "!bunfig.toml" "!deno.lock" "!bun.lockb" "!deno.json"];
      };
      deno = {
        format = "via [🦕 $version](green bold) ";
      };
      custom = {
        supabase = {
          command = "${pkgs.supabase-cli}/bin/supabase -v";
          format = "via [⚡ $output](green bold) ";
          detect_folders = ["supabase"];
          ignore_timeout = true;
        };
      };
      nix_shell = {
        format = "[$symbol] ";
        impure_msg = "";
        pure_msg = "";
      };
    };
  };

  programs.zoxide = {
    enable = true;
    enableNushellIntegration = true;
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
    enableNushellIntegration = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
  };

  programs.zellij = {
    enable = true;
    enableFishIntegration = false;
  };

  programs.fastfetch = {
    enable = true;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
      logo = {
        source = ../desktop/assets/logo.png;
        type = "kitty";
        height = 15;
        width = 30;
        padding = {
          top = 5;
          left = 3;
        };
      };
      modules = [
        "break"
        {
          type = "custom";
          format = "┌──────────────────────Hardware───────────────────────────────┐";
        }
        {
          type = "host";
          key = " PC";
          keyColor = "green";
        }
        {
          type = "cpu";
          key = "│ ├";
          showPeCoreCount = true;
          keyColor = "green";
        }
        {
          type = "gpu";
          key = "│ ├󰍛";
          keyColor = "green";
        }
        {
          type = "disk";
          key = "│ ├";
          keyColor = "green";
        }
        {
          type = "memory";
          key = "└─└󰍛";
          keyColor = "green";
        }
        {
          type = "custom";
          format = "└─────────────────────────────────────────────────────────────┘";
        }
        "break"
        {
          type = "custom";
          format = "┌──────────────────────Software───────────────────────────────┐";
        }
        {
          type = "os";
          key = "󱄅 OS";
          keyColor = "yellow";
        }
        {
          type = "kernel";
          key = "│ ├";
          keyColor = "yellow";
        }
        {
          type = "packages";
          key = "│ ├󰏖";
          keyColor = "yellow";
        }
        {
          type = "shell";
          key = "└ └";
          keyColor = "yellow";
        }
        "break"
        {
          type = "de";
          key = " DE";
          keyColor = "blue";
        }
        {
          type = "lm";
          key = "│ ├";
          keyColor = "blue";
        }
        {
          type = "wm";
          key = "│ ├";
          keyColor = "blue";
        }
        {
          type = "wmtheme";
          key = "│ ├󰉼";
          keyColor = "blue";
        }
        {
          type = "gpu";
          key = "└ └󰍛";
          format = "{3}";
          keyColor = "blue";
        }
        {
          type = "custom";
          format = "└─────────────────────────────────────────────────────────────┘";
        }
        "break"
        {
          type = "custom";
          format = "┌────────────────────Uptime / Age─────────────────────────────┐";
        }
        {
          type = "command";
          key = "  OS Age";
          keyColor = "magenta";
          text = "birth_install=$(stat -c %W /); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days";
        }
        {
          type = "uptime";
          key = "  Uptime";
          keyColor = "magenta";
        }
        {
          type = "custom";
          format = "└─────────────────────────────────────────────────────────────┘";
        }
        "break"
      ];
    };
  };
}
