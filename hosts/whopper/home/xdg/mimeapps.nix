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
  #
  # Plasma's "Default Applications" KCM and several GTK apps rewrite
  # ~/.config/mimeapps.list in place, which turns the home-manager symlink into
  # a real file and made every rebuild fail on a stale .hm-backup. Take
  # ownership outright instead: the list below is authoritative, so anything an
  # app registers into [Added Associations] at runtime is discarded on rebuild.
  # Consequence: a handler that only ever existed at runtime must be declared
  # here or it is lost — see the scheme handlers at the end of the set.
  xdg.configFile."mimeapps.list".force = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = ["nemo.desktop" "yazi.desktop"];
      "application/pdf" = ["org.gnome.Papers.desktop" "org.gnome.Evince.desktop"];
      "text/html" = "zen.desktop";
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
      "application/x-extension-htm" = "zen.desktop";
      "application/x-extension-html" = "zen.desktop";
      "application/x-extension-shtml" = "zen.desktop";
      "application/xhtml+xml" = "zen.desktop";
      "application/x-extension-xhtml" = "zen.desktop";
      "application/x-extension-xht" = "zen.desktop";
      "x-scheme-handler/http" = "zen.desktop";
      "x-scheme-handler/https" = "zen.desktop";
      "x-scheme-handler/chrome" = "zen.desktop";
      "x-scheme-handler/about" = "zen.desktop";
      "x-scheme-handler/unknown" = "zen.desktop";
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

      # Registered by the apps themselves into [Added Associations] rather than
      # declared here, so they only survived because the file was writable.
      # Declared explicitly now that home-manager owns the file outright.
      "x-scheme-handler/slack" = "slack.desktop";
      "x-scheme-handler/abc" = "plexamp.desktop";
      "x-scheme-handler/cider" = "cider-2.desktop";
      "x-scheme-handler/itms" = "cider-2.desktop";
      "x-scheme-handler/itmss" = "cider-2.desktop";
      "x-scheme-handler/itunes" = "cider-2.desktop";
      "x-scheme-handler/music" = "cider-2.desktop";
    };
  };
}
