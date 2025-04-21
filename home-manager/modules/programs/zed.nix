{
  config,
  pkgs,
  ...
}: let
  zedConfig = {
    assistant = {
      default_model = {
        model = "claude-3-7-sonnet-latest";
        provider = "anthropic";
      };
      version = 2;
    };
    auto_update = false;
    buffer_font_family = "SFMono Nerd Font";
    buffer_font_size = 18;
    features = {
      edit_prediction_provider = "copilot";
    };
    file_types = {
      HTML = ["html" "svg"];
    };
    font_family = "SFMono Nerd Font";
    languages = {
      Nix = {
        format_on_save = {
          external = {
            arguments = [];
            command = "${pkgs.alejandra}/bin/alejandra";
          };
        };
      };
    };
    relative_line_numbers = false;
    soft_wrap = "editor_width";
    ssh_connections = [
      {
        host = "10.24.24.2";
        nickname = "BigTasty";
        projects = [
          {
            paths = ["~/.nixfiles"];
          }
        ];
        upload_binary_over_ssh = false;
        username = "psoldunov";
      }
    ];
    terminal = {
      copy_on_select = true;
      font_size = 18;
    };
    ui_font_size = 18;
    vim_mode = false;
  };
in {
  programs.zed-editor = {
    enable = true;
    installRemoteServer = true;
    userSettings = zedConfig;
    extensions = [
      "html"
      "toml"
      "git-firefly"
      "scss"
      "nix"
    ];
  };

  home.file."${config.xdg.dataHome}/zed/languages/package-version-server/package-version-server-v0.0.7" = {
    source = pkgs.writeShellScript "package-version-server-v0.0.7" ''
      ${pkgs.package-version-server}/bin/package-version-server
    '';
    executable = true;
  };

  home.file."${config.xdg.dataHome}/zed/languages/rust-analyzer/rust-analyzer-2025-01-08" = {
    source = pkgs.writeShellScript "rust-analyzer-2025-01-08" ''
      ${pkgs.rust-analyzer}/bin/rust-analyzer
    '';
    executable = true;
  };

  home.file."${config.xdg.dataHome}/zed/extensions/work/discord-presence" = {
    source = "${pkgs.zed-discord-presence}/bin/";
    force = true;
    recursive = true;
  };
}
