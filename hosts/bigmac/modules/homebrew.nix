# What BigMac takes from Homebrew. The split:
#
#   - Every GUI app is a cask; App Store-only apps are masApps.
#   - Agent CLIs that ship several releases a week are formulae (codex is
#     upstream's cask), so they stay ahead of nixpkgs.
#   - Formulae that live only in third-party taps, or are macOS-specific and
#     missing from nixpkgs, stay here too.
#   - Every other CLI comes from nixpkgs: the shared set in
#     modules/home/workstation/cli.nix plus hosts/bigmac/home/packages.nix.
#     Claude Code and pi come from this repo's overlays; node, bun, deno and
#     python come from mise.
#
# `rebuild_system` installs what is missing and never upgrades
# (autoUpdate/upgrade off); `update_system` runs `brew update && brew
# upgrade` through `update_bleeding_edge`. With cleanup = "uninstall" a
# rebuild removes any formula, cask or tap not listed here, keeping app data.
{lib, ...}: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "uninstall";
    };

    # Sets HOMEBREW_BUNDLE_FILE, so a bare `brew bundle check` reads the
    # Brewfile generated from this module.
    global.brewfile = true;

    # Homebrew 6+ refuses formulae and casks from untrusted third-party taps.
    taps =
      map (name: {
        inherit name;
        trusted = true;
      }) [
        "antoniorodr/memo"
        "browsh-org/browsh"
        "ensemblr-hq/tap"
        "mongodb/brew"
        "nubjs/tap"
        "openclaw/tap"
        "psoldunov/tap"
        "steipete/tap"
        "teamookla/speedtest"
        "xykong/tap"
        "yakitrak/yakitrak"
      ];

    brews = [
      # Bleeding-edge agent CLI (codex is upstream's cask, below).
      "mistral-vibe"

      # Vendor CLIs that move faster than nixpkgs.
      "ctx7"
      "neonctl"
      "vercel"

      # macOS-specific, or absent from nixpkgs.
      "libpq"
      "openai-whisper"
      "summarize"

      # Runs as a brew service (Syncthing device "BigMac").
      "syncthing"

      # Third-party taps.
      "antoniorodr/memo/memo"
      "browsh-org/browsh/browsh"
      "mongodb/brew/mongodb-database-tools"
      "nubjs/tap/nub"
      "openclaw/tap/gogcli"
      "steipete/tap/gifgrep"
      "steipete/tap/remindctl"
      "teamookla/speedtest/speedtest"
      "yakitrak/yakitrak/notesmd-cli"
    ];

    casks = [
      # Agent CLI, upstream ships it as a cask.
      "codex"
      "1password"
      "1password-cli"
      "affinity-designer"
      "affinity-photo"
      "affinity-publisher"
      "asana"
      "atuin-desktop"
      "balenaetcher"
      "bambu-studio"
      "bitwarden"
      "chatgpt"
      "claude"
      "cleanshot"
      "cyberduck"
      "discord"
      "downie"
      "dropzone"
      "ensemblr-hq/tap/ensemblr"
      "expressvpn"
      "figma"
      "xykong/tap/flux-markdown"
      "font-jetbrains-mono-nerd-font"
      "geekbench"
      "ghostty"
      "github"
      "google-chrome"
      "iina"
      "keymapp"
      "klokki"
      "ledger-wallet"
      "linear"
      "linear-linear"
      "localsend"
      "loopback"
      # Mail client whose built-in MCP server Claude Code uses
      # (modules/home/workstation/mailspring.nix).
      "mailspring"
      "motrix"
      "nextcloud"
      "notion"
      "notion-calendar"
      "notunes"
      "numi"
      "obsidian"
      "onyx"
      "orbstack"
      "plexamp"
      "postman"
      "puremac"
      "qflipper"
      "raycast"
      "rectangle"
      "renamer"
      "psoldunov/tap/skrepka"
      "slack"
      "soundsource"
      "steermouse"
      "telegram-desktop"
      "tg-pro"
      # Also feeds Claude Code's statusline (hosts/bigmac/home/default.nix).
      "psoldunov/tap/token-station"
      "transmission-remote-gui"
      "transmit"
      "visual-studio-code"
      "vorssaint"
      "zed"
      "zen"
      "zoom"
    ];

    # Installing these needs an App Store sign-in on the Mac.
    masApps = {
      "1Password for Safari" = 1569813296;
      "Color Picker" = 1545870783;
      "Compressor" = 424390742;
      "Developer" = 640199958;
      "DigiDoc4" = 1370791134;
      "Dropover" = 1355679052;
      "ExcalidrawZ" = 6636493997;
      "Final Cut Pro" = 424389933;
      "Gapplin" = 768053424;
      "Infuse" = 1136220934;
      "Keynote" = 409183694;
      "Keystroke Pro" = 1572206224;
      "Motion" = 434290957;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Parcel" = 375589283;
      "RunCatNeo" = 6757801838;
      "Velja" = 1607635845;
      "Web eID" = 1576665083;
      "WhatsApp" = 310633997;
      "Xcode" = 497799835;
    };
  };

  # Homebrew's bin dirs after the Nix profiles, so Nix wins when a tool is in
  # both, but ahead of macOS's own /usr/bin. The homebrew module's
  # enable*Integration would prepend them instead.
  environment.systemPath = lib.mkOrder 1100 ["/opt/homebrew/bin" "/opt/homebrew/sbin"];
}
