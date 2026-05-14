{pkgs, ...}: {
  xdg = {
    mime.enable = true;
    portal = {
      enable = true;
      config = {
        common = {
          "org.freedesktop.portal.FileChooser" = [
            "gtk"
          ];
          "org.freedesktop.portal.Secret" = [
            "gnome-keyring"
          ];
        };
      };
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };
  };
}
