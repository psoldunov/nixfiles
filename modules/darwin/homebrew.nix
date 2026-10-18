# What every Mac takes from Homebrew. hosts/<host>/modules/homebrew.nix
# adds the apps only that host gets, so a GUI app lives here only when both
# BigMac and MacFlurry want it. nix-darwin merges the lists. The split:
#
#   - Every GUI app is a cask; App Store-only apps are masApps.
#   - Agent CLIs that ship several releases a week are formulae (codex is
#     upstream's cask), so they stay ahead of nixpkgs.
#   - Formulae that live only in third-party taps, or are macOS-specific and
#     missing from nixpkgs, stay here too.
#   - Every other CLI comes from nixpkgs: the shared set in
#     modules/home/workstation/cli.nix plus modules/home/darwin/packages.nix.
#     Claude Code and pi come from this repo's overlays; node, bun, deno and
#     python come from mise.
#
# `rebuild_system` installs what is missing and never upgrades
# (autoUpdate/upgrade off); `update_system` runs `brew update && brew
# upgrade` through `update_bleeding_edge`. With cleanup = "uninstall" a
# rebuild removes any formula, cask or tap that neither this file nor the
# host's lists, keeping app data.
{lib, ...}: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "uninstall";
    };

    # Sets HOMEBREW_BUNDLE_FILE, so a bare `brew bundle check` reads the
    # Brewfile generated from these modules.
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
      "fallow"
      "libpq"
      "openai-whisper"
      "summarize"

      # Runs as a brew service, peered with Whopper and BigTasty.
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
      "balenaetcher"
      "bambu-studio"
      "bitwarden"
      "cleanshot"
      "cyberduck"
      "discord"
      "ensemblr-hq/tap/ensemblr"
      "figma"
      "font-jetbrains-mono-nerd-font"
      "ghostty"
      "github"
      "google-chrome"
      "iina"
      "linear"
      "localsend"
      # Mail client whose built-in MCP server Claude Code uses
      # (modules/home/workstation/mailspring.nix).
      "mailspring"
      "nextcloud"
      "notion"
      "notion-calendar"
      "notunes"
      "numi"
      "obsidian"
      "orbstack"
      "plexamp"
      "postman"
      "puremac"
      "raycast"
      "rectangle"
      "screen-studio"
      "psoldunov/tap/skrepka"
      "slack"
      "telegram-desktop"
      "tg-pro"
      # Also feeds Claude Code's statusline (modules/home/darwin/default.nix).
      "psoldunov/tap/token-station"
      "transmission-remote-gui"
      "transmit"
      "visual-studio-code"
      "vorssaint"
      "whatsapp"
      "zed"
      "zen"
      "zoom"
    ];

    # Installing these needs an App Store sign-in on the Mac.
    masApps = {
      "Developer" = 640199958;
      "Infuse" = 1136220934;
      "Parcel" = 375589283;
      "Velja" = 1607635845;
      "Xcode" = 497799835;
    };
  };

  # Homebrew's bin dirs after the Nix profiles, so Nix wins when a tool is in
  # both, but ahead of macOS's own /usr/bin. The homebrew module's
  # enable*Integration would prepend them instead.
  environment.systemPath = lib.mkOrder 1100 ["/opt/homebrew/bin" "/opt/homebrew/sbin"];

  environment.variables = {
    # Homebrew 7 asks for confirmation before every install and upgrade.
    HOMEBREW_NO_ASK = "1";
    HOMEBREW_NO_ENV_HINTS = "1";
  };
}
