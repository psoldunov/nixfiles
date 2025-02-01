{
  config,
  pkgs,
  globalSettings,
  lib,
  ...
}: {
  home.sessionVariables = {
    GOPATH = "/home/psoldunov/.go";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    DENO_INSTALL = "/home/psoldunov/.deno";
    PATH = "HOME/.local/bin:/usr/sbin:$HOME/.local/podman/bin:$HOME/.cargo/bin:$DENO_INSTALL/bin:$PATH";
    TERMINAL = "ghostty";
    TERM = "xterm-256color";
    MAILER = "${pkgs.thunderbird}/bin/thunderbird";
    # VSCODE_GALLERY_SERVICE_URL = "https://marketplace.visualstudio.com/_apis/public/gallery";
    # VSCODE_GALLERY_ITEM_URL = "https://marketplace.visualstudio.com/items";
    # VSCODE_GALLERY_CACHE_URL = "https://vscode.blob.core.windows.net/gallery/index";
    # VSCODE_GALLERY_CONTROL_URL = "";
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
      # set -Ua fish_user_paths $HOME/.cargo/bin
      # set --export BUN_INSTALL "$HOME/.bun"
      # set --export PATH $BUN_INSTALL/bin $PATH
      # set fish_greeting
      # set fish_color_normal normal
      # set fish_color_command 88c0d0
      # set fish_color_keyword 81a1c1
      # set fish_color_quote a3be8c
      # set fish_color_redirection b48ead --bold
      # set fish_color_end 81a1c1
      # set fish_color_error bf616a
      # set fish_color_param d8dee9
      # set fish_color_valid_path --underline
      # set fish_color_option 8fbcbb
      # set fish_color_comment 4c566a --italics
      # set fish_color_selection d8dee9 --bold --background=434c5e
      # set fish_color_operator 81a1c1
      # set fish_color_escape ebcb8b
      # set fish_color_autosuggestion 4c566a
      # set fish_color_cwd 5e81ac
      # set fish_color_cwd_root bf616a
      # set fish_color_user a3be8c
      # set fish_color_host a3be8c
      # set fish_color_host_remote ebcb8b
      # set fish_color_status bf616a
      # set fish_color_cancel --reverse
      # set fish_color_match --background=brblue
      # set fish_color_search_match --bold --background=434c5e
      # set fish_color_history_current e5e9f0 --bold
      # set fish_pager_color_progress 3b4252 --background=d08770
      # set fish_pager_color_completion e5e9f0
      # set fish_pager_color_prefix normal --bold --underline
      # set fish_pager_color_description ebcb8b --italics
      # set fish_pager_color_selected_background --background=434c5e
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
    thunar = "nemo";
    # ssh = "kitten ssh";
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
    # settings = {
    #   "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
    #   logo = {
    #     source = ../desktop/assets/logo.png;
    #     type = "kitty";
    #     height = 15;
    #     width = 30;
    #     padding = {
    #       top = 5;
    #       left = 3;
    #     };
    #   };
    #   modules = [
    #     "break"
    #     {
    #       type = "custom";
    #       format = "┌──────────────────────Hardware───────────────────────────────┐";
    #     }
    #     {
    #       type = "host";
    #       key = " PC";
    #       keyColor = "green";
    #     }
    #     {
    #       type = "cpu";
    #       key = "│ ├";
    #       showPeCoreCount = true;
    #       keyColor = "green";
    #     }
    #     {
    #       type = "gpu";
    #       key = "│ ├󰍛";
    #       keyColor = "green";
    #     }
    #     {
    #       type = "disk";
    #       key = "│ ├";
    #       keyColor = "green";
    #     }
    #     {
    #       type = "memory";
    #       key = "└─└󰍛";
    #       keyColor = "green";
    #     }
    #     {
    #       type = "custom";
    #       format = "└─────────────────────────────────────────────────────────────┘";
    #     }
    #     "break"
    #     {
    #       type = "custom";
    #       format = "┌──────────────────────Software───────────────────────────────┐";
    #     }
    #     {
    #       type = "os";
    #       key = "󱄅 OS";
    #       keyColor = "yellow";
    #     }
    #     {
    #       type = "kernel";
    #       key = "│ ├";
    #       keyColor = "yellow";
    #     }
    #     {
    #       type = "packages";
    #       key = "│ ├󰏖";
    #       keyColor = "yellow";
    #     }
    #     {
    #       type = "shell";
    #       key = "└ └";
    #       keyColor = "yellow";
    #     }
    #     "break"
    #     {
    #       type = "de";
    #       key = " DE";
    #       keyColor = "blue";
    #     }
    #     {
    #       type = "lm";
    #       key = "│ ├";
    #       keyColor = "blue";
    #     }
    #     {
    #       type = "wm";
    #       key = "│ ├";
    #       keyColor = "blue";
    #     }
    #     {
    #       type = "wmtheme";
    #       key = "│ ├󰉼";
    #       keyColor = "blue";
    #     }
    #     {
    #       type = "gpu";
    #       key = "└ └󰍛";
    #       format = "{3}";
    #       keyColor = "blue";
    #     }
    #     {
    #       type = "custom";
    #       format = "└─────────────────────────────────────────────────────────────┘";
    #     }
    #     "break"
    #     {
    #       type = "custom";
    #       format = "┌────────────────────Uptime / Age─────────────────────────────┐";
    #     }
    #     {
    #       type = "command";
    #       key = "  OS Age";
    #       keyColor = "magenta";
    #       text = "birth_install=$(stat -c %W /); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days";
    #     }
    #     {
    #       type = "uptime";
    #       key = "  Uptime";
    #       keyColor = "magenta";
    #     }
    #     {
    #       type = "custom";
    #       format = "└─────────────────────────────────────────────────────────────┘";
    #     }
    #     "break"
    #   ];
    # };
  };
}
