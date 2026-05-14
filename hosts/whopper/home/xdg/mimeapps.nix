{...}: {
  # User-level mirror of the system mime defaults from
  # modules/nixos/desktop-environment.nix.
  #
  # Why: sandboxed apps (notably Steam's bwrap FHS env) replace /etc with
  # their own rootfs, so the host's /etc/xdg/mimeapps.list is invisible.
  # Only ~/.config/mimeapps.list is reachable through the bind-mounted
  # home directory, so any defaults we want Steam etc. to honor must live
  # here too. Without this, Steam's "Browse local files" falls back to
  # $TERMINAL (kitty) because no inode/directory handler is found.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = ["nemo.desktop" "yazi.desktop"];
      "application/pdf" = ["org.gnome.Papers.desktop" "org.gnome.Evince.desktop"];
      "text/html" = "brave-browser.desktop";
      "text/plain" = "code.desktop";
      "image/jpeg" = "org.gnome.eog.desktop";
      "image/png" = "org.gnome.eog.desktop";
      "image/svg+xml" = "org.gnome.eog.desktop";
      "image/gif" = "org.gnome.eog.desktop";
      "image/webp" = "org.gnome.eog.desktop";
      "image/avif" = "org.gnome.eog.desktop";
      "video/mp4" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "writer.desktop";
      "application/lrf" = "calibre-lrfviewer.desktop";
      "message/rfc822" = "thunderbird.desktop";
      "application/rss+xml" = "thunderbird.desktop";
      "application/x-extension-rss" = "thunderbird.desktop";
      "application/x-extension-ics" = "thunderbird.desktop";
      "text/calendar" = "thunderbird.desktop";
      "application/x-extension-htm" = "brave-browser.desktop";
      "application/x-extension-html" = "brave-browser.desktop";
      "application/x-extension-shtml" = "brave-browser.desktop";
      "application/xhtml+xml" = "brave-browser.desktop";
      "application/x-extension-xhtml" = "brave-browser.desktop";
      "application/x-extension-xht" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/chrome" = "brave-browser.desktop";
      "x-scheme-handler/about" = "brave-browser.desktop";
      "x-scheme-handler/unknown" = "brave-browser.desktop";
      "x-scheme-handler/vscode" = "code-url-handler.desktop";
      "x-scheme-handler/magnet" = "io.github.TransmissionRemoteGtk.desktop";
      "x-scheme-handler/mailto" = "thunderbird.desktop";
      "x-scheme-handler/mid" = "thunderbird.desktop";
      "x-scheme-handler/news" = "thunderbird.desktop";
      "x-scheme-handler/snews" = "thunderbird.desktop";
      "x-scheme-handler/nntp" = "thunderbird.desktop";
      "x-scheme-handler/feed" = "thunderbird.desktop";
      "x-scheme-handler/webcal" = "thunderbird.desktop";
      "x-scheme-handler/webcals" = "thunderbird.desktop";
      "x-scheme-handler/figma" = "figma-linux.desktop";
      "x-scheme-handler/whatsapp" = "whatsie.desktop";
      "x-scheme-handler/heroic" = "com.heroicgameslauncher.hgl.desktop";
      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
      "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
      "x-scheme-handler/msteams" = "teams-for-linux.desktop";
      "x-scheme-handler/notion" = "notion-app-enhanced.desktop";
      "x-scheme-handler/anytype" = "anytype.desktop";
      "x-scheme-handler/discord" = "legcord.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    };
  };
}
