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
          # KWallet (via ksecretd) backs the Secret portal and owns
          # org.freedesktop.secrets. The kwallet.portal backend file comes from
          # kdePackages.kwallet, which services.desktopManager.plasma6 already
          # registers system-wide.
          "org.freedesktop.portal.Secret" = [
            "kwallet"
          ];
        };
      };
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };
  };
}
