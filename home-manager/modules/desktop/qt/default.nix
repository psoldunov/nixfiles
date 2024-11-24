{
  lib,
  config,
  globalSettings,
  pkgs,
  ...
}: let
  defaultFont = {
    family = "SF Pro Display";
    weight = "Regular";
    size = "12";
  };

  qtCatppuccin = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/catppuccin/qt5ct/89ee948e72386b816c7dad72099855fb0d46d41e/themes/Catppuccin-Mocha.conf";
    sha256 = "06rh1sjd1a16ksqdhg83yrdja9lwrm9vh1b57xawigaz9w2z7ail";
  };

  qtConfig = {
    Appearance = {
      color_scheme_path = qtCatppuccin;
      custom_palette = true;
      standard_dialogs = "gtk3";
      style = "Fusion";
    };
    Interface = {
      activate_item_on_single_click = 1;
      buttonbox_layout = 0;
      cursor_flash_time = 1000;
      dialog_buttons_have_icons = 1;
      double_click_interval = 400;
      gui_effects = "@Invalid()";
      keyboard_scheme = 2;
      menus_have_icons = true;
      show_shortcuts_in_context_menus = true;
      stylesheets = "@Invalid()";
      toolbutton_style = 4;
      underline_shortcut = 1;
      wheel_scroll_lines = 3;
    };

    SettingsWindow = {
      geometry = ''@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\0\0\0\0\0\0\0\0\as\0\0\x4\x11\0\0\0\0\0\0\0\0\0\0\a\x7f\0\0\x4\x1d\0\0\0\0\x2\0\0\0\xf\0\0\0\0\0\0\0\0\0\0\0\as\0\0\x4\x11)'';
    };

    Troubleshooting = {
      force_raster_widgets = 1;
      ignored_applications = "@Invalid()";
    };
  };

  qt5config =
    (pkgs.formats.toml {}).generate "qt5Config"
    (qtConfig
      // {
        Fonts = {
          fixed = ''${defaultFont.family},${defaultFont.size},-1,5,50,0,0,0,0,0,${defaultFont.weight}'';
          general = ''${defaultFont.family},${defaultFont.size},-1,5,50,0,0,0,0,0,${defaultFont.weight}'';
        };
      });

  qt6config =
    (pkgs.formats.toml {}).generate "qt6Config"
    (qtConfig
      // {
        Fonts = {
          fixed = ''${defaultFont.family},${defaultFont.size},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,${defaultFont.weight}'';
          general = ''${defaultFont.family},${defaultFont.size},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,${defaultFont.weight}'';
        };
      });
in {
  qt = {
    enable = true;
    platformTheme.name = lib.mkIf globalSettings.enableHyprland "qtct";
    style = {
      catppuccin.enable = false;
    };
  };

  home.file = lib.mkIf globalSettings.enableHyprland {
    ".config/qt5ct/qt5ct.conf" = {
      source = qt5config;
    };
    ".config/qt6ct/qt6ct.conf" = {
      source = qt6config;
    };
  };
}
