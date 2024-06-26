{
  config,
  libs,
  pkgs,
  ...
}: let
  setSecrets = ''
    export GH_TOKEN="$(cat ${config.sops.secrets.GH_TOKEN.path})"
    export NPM_TOKEN="$(cat ${config.sops.secrets.NPM_TOKEN.path})"
    export RESEND_API_KEY="$(cat ${config.sops.secrets.RESEND_API_KEY.path})"
    export OPENAI_API_KEY="$(cat ${config.sops.secrets.OPENAI_API_KEY.path})"
  '';
in {
  home.sessionVariables = {
    STARSHIP_DISTRO = "";
    GOPATH = "/home/psoldunov/.go";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    DENO_INSTALL = "/home/psoldunov/.deno";
    PATH = "HOME/.local/bin:/usr/sbin:$HOME/.local/podman/bin:$HOME/.cargo/bin:$DENO_INSTALL/bin:$PATH";
    TERMINAL = "kitty";
    TERM = "xterm-256color";
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      reload = "source ~/.config/fish/config.fish && echo 'FISH config reloaded.'";
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
      resetDE = {
        body = ''
          pkill -9 waybar
          pkill -9 swaync
          hyprctl reload
          waybar
          swaync
        '';
      };
    };
    shellInit = ''
      set -Ua fish_user_paths $HOME/.cargo/bin
      set --export BUN_INSTALL "$HOME/.bun"
      set --export PATH $BUN_INSTALL/bin $PATH
      set fish_greeting
    '';
    shellInitLast = setSecrets;
  };

  home.shellAliases = {
    ls = "lsd -laFh";
    rm = "gio trash";
    fucking = "sudo";
    cat = "bat";
    thunar = "nemo";
    ssh = "kitten ssh";
  };

  programs.bash = {
    enable = true;
    enableVteIntegration = true;
    enableCompletion = true;
    bashrcExtra = setSecrets;
  };

  programs.keychain = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    keys = [
      "git"
    ];
  };

  programs.thefuck = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    settings = {
      add_newline = true;
      command_timeout = 1000;
      format = "$env_var $all";
      character = {
        success_symbol = "";
        error_symbol = "";
      };
      env_var.A_STARSHIP_SHELL = {
        format = ''\([$env_value](bold red)\) '';
        variable = "STARSHIP_SHELL";
        disabled = false;
      };
      env_var.STARSHIP_DISTRO = {
        format = ''[$env_value](bold blue) '';
        variable = "STARSHIP_DISTRO";
        disabled = false;
      };
      env_var.USER = {
        format = ''[$env_value](bold white) on'';
        variable = "USER";
        disabled = false;
      };
      hostname = {
        ssh_only = false;
        format = ''[$hostname](bold yellow) '';
        disabled = false;
      };
      directory = {
        truncation_length = 1;
        truncation_symbol = "…/";
        home_symbol = " ~";
        read_only_style = "197";
        read_only = "  ";
        format = "at [$path]($style)[$read_only]($read_only_style) ";
      };
      git_branch = {
        symbol = " ";
        format = "via [$symbol$branch]($style) ";
        truncation_symbol = "…/";
        style = "bold green";
      };
      git_status = {
        format = ''[\($all_status$ahead_behind\)]($style) '';
        style = "bold green";
        conflicted = "🏳";
        up_to_date = " ";
        untracked = " ";
        ahead = ''⇡$count'';
        diverged = ''⇕⇡{$ahead_count}⇣{$behind_count}'';
        behind = ''⇣{$count}'';
        stashed = " ";
        modified = " ";
        staged = ''[++\($count\)](green)'';
        renamed = "襁 ";
        deleted = " ";
      };
      kubernetes = {
        format = ''via [ﴱ $context\($namespace\)](bold purple) '';
        disabled = false;
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

  programs.zellij = {
    enable = true;
    enableFishIntegration = false;
  };
}
