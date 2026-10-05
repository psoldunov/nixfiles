# Default applications for Whopper. Single source for both the system-wide
# list (modules/desktop-environment.nix -> /etc/xdg/mimeapps.list) and the
# user-level list (home/xdg/mimeapps.nix -> ~/.config/mimeapps.list); see the
# latter for why both exist. The two lists used to be maintained by hand and
# drifted apart.
#
# Values are desktop-file IDs as installed under share/applications. Desktop
# handlers are the KDE apps the plasma6 module ships (Dolphin, Okular,
# Gwenview, Ark, Elisa); MIME keys are the canonical shared-mime-info names.
let
  browser = "zen.desktop";
  # Wye (home/programs/wye.nix) picks the browser for every web link; its
  # desktop entry claims only the http and https schemes, so local HTML files
  # and the other browser schemes stay with Zen.
  linkPicker = "dev.soldunov.wye.desktop";
  mail = "thunderbird.desktop";
  editor = "code.desktop";
  imageViewer = "org.kde.gwenview.desktop";
  videoPlayer = "mpv.desktop";
  musicPlayer = "org.kde.elisa.desktop";
  archiver = "org.kde.ark.desktop";
  torrentClient = "org.equeim.Tremotesf.desktop";
  cider = "cider-2.desktop";
  telegram = "org.telegram.desktop.desktop";

  # Map every MIME type in `types` to the same handler.
  handledBy = handler: types:
    builtins.listToAttrs (map (type: {
        name = type;
        value = handler;
      })
      types);
in
  handledBy browser [
    "text/html"
    "application/xhtml+xml"
    "application/x-extension-htm"
    "application/x-extension-html"
    "application/x-extension-shtml"
    "application/x-extension-xhtml"
    "application/x-extension-xht"
    "x-scheme-handler/chrome"
    "x-scheme-handler/about"
    "x-scheme-handler/unknown"
  ]
  // handledBy linkPicker [
    "x-scheme-handler/http"
    "x-scheme-handler/https"
  ]
  // handledBy mail [
    "message/rfc822"
    "x-scheme-handler/mailto"
    "x-scheme-handler/mid"
    "x-scheme-handler/news"
    "x-scheme-handler/snews"
    "x-scheme-handler/nntp"
    "x-scheme-handler/feed"
    "application/rss+xml"
    "application/x-extension-rss"
    "text/calendar"
    "application/x-extension-ics"
    "x-scheme-handler/webcal"
    "x-scheme-handler/webcals"
  ]
  // handledBy imageViewer [
    "image/jpeg"
    "image/png"
    "image/svg+xml"
    "image/gif"
    "image/webp"
    "image/avif"
  ]
  // handledBy videoPlayer [
    "video/mp4"
    "video/webm"
    "video/x-matroska"
  ]
  // handledBy musicPlayer [
    "audio/mpeg"
    "audio/flac"
    "audio/ogg"
    "audio/x-vorbis+ogg"
    "audio/x-opus+ogg"
    "audio/mp4"
    "audio/vnd.wave"
  ]
  // handledBy archiver [
    "application/zip"
    "application/x-7z-compressed"
    "application/vnd.rar"
    "application/gzip"
    "application/x-tar"
    "application/x-compressed-tar"
    "application/x-xz-compressed-tar"
    "application/x-zstd-compressed-tar"
  ]
  // handledBy torrentClient [
    "x-scheme-handler/magnet"
    "application/x-bittorrent"
  ]
  // handledBy cider [
    "x-scheme-handler/cider"
    "x-scheme-handler/itms"
    "x-scheme-handler/itmss"
    "x-scheme-handler/itunes"
    "x-scheme-handler/music"
  ]
  // handledBy telegram [
    "x-scheme-handler/tg"
    "x-scheme-handler/tonsite"
  ]
  // {
    # Listed in preference order: yazi only opens folders if Dolphin cannot.
    "inode/directory" = ["org.kde.dolphin.desktop" "yazi.desktop"];
    "application/pdf" = "okularApplication_pdf.desktop";
    "text/plain" = editor;
    # Notion's desktop entry claims text/markdown, which would outrank the
    # text/plain fallback. Keep Markdown files in the editor.
    "text/markdown" = editor;
    "application/lrf" = "calibre-lrfviewer.desktop";

    "x-scheme-handler/vscode" = "code-url-handler.desktop";
    "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    "x-scheme-handler/heroic" = "com.heroicgameslauncher.hgl.desktop";
    "x-scheme-handler/discord" = "discord.desktop";
    "x-scheme-handler/slack" = "slack.desktop";
    "x-scheme-handler/abc" = "plexamp.desktop";
    "x-scheme-handler/figma" = "figma.desktop";
    "x-scheme-handler/linear" = "linear.desktop";
    "x-scheme-handler/notion" = "notion.desktop";
  }
