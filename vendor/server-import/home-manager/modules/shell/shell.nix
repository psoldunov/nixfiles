{
  config,
  libs,
  pkgs,
  ...
}: {
  home.sessionVariables = {
    GOPATH = "/home/psoldunov/.go";
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
    };
    shellInit = ''
      export STARSHIP_DISTRO=""
      set fish_greeting
    '';
    shellInitLast = "source ${config.sops.secrets.SHELL_SECRETS.path}";
  };

  home.shellAliases = {
    ls = "lsd -laFh";
    vim = "nvim";
    rm = "gio trash";
    fucking = "sudo";
    cat = "bat";
    thunar = "nemo";
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
      # "git"
    ];
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    settings = {
      format = "$env_var $all";
      hostname = {
        ssh_only = true;
        disabled = false;
      };
      bun = {
        format = "via [🥟 $version](bold green) ";
      };
      nodejs = {
        detect_files = ["package.json" ".node-version" "!bunfig.toml" "!bun.lockb" "!deno.json"];
      };
      deno = {
        format = "via [🦕 $version](green bold) ";
      };
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = [
      "--cmd j"
    ];
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zellij = {
    enable = true;
    enableFishIntegration = false;
    settings = {
      theme = "catppuccin-mocha";
    };
  };
}
