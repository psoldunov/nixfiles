{pkgs, ...}: {
  "settings.ini" = {
    source =
      (pkgs.formats.ini {}).generate "settings.ini"
      {
        general = {
          theme = "dark";
          font_size = 12;
          show_tabs_bar = false;
          tab_width = 30;
          tab_max_width = 50;
          tab_min_width = 10;
        };
      };
  };
}
