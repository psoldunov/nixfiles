# BigMac's Stream Deck MK.2: the pages in ./decks.nix, run as a launchd agent
# by the shared deckmaster module in modules/home/programs/deckmaster, whose
# lib.nix holds the key helpers both hosts use. What is here is macOS's: app
# launches through `open`, the apps' own icons, the mic toggle and the Clokkr
# CLI inside its app bundle.
#
# deckmaster posts the `keycode` presses (media and volume keys, the lock and
# screenshot chords) as CoreGraphics events, which macOS drops until the
# deckmaster binary has Accessibility permission: System Settings › Privacy &
# Security › Accessibility, then add the path that
# `readlink -f "$(command -v deckmaster)"` prints. macOS ties the grant to that
# exact binary, so it has to be granted again after each bump of the
# `deckmaster` flake input. A change to the decks keeps it, since the pages
# are only an argument to the same binary.
{
  lib,
  pkgs,
  inputs,
  ...
}: let
  deck = import ../../../../../modules/home/programs/deckmaster/lib.nix {inherit lib pkgs inputs;};
  inherit (deck) run;

  # A script name for the app at `app`, a bundle path or an app name. It drops
  # `.app`, since macOS kills any program whose file name ends in it.
  scriptName = app: lib.strings.sanitizeDerivationName (lib.removeSuffix ".app" (baseNameOf app));

  # Opens an app the way the Dock does.
  launch = app:
    run "launch-${scriptName app}" ''
      exec /usr/bin/open -a ${lib.escapeShellArg app}
    '';

  appIconScript = lib.getExe (pkgs.writeShellApplication {
    name = "deckmaster-app-icon";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      # deckmaster-app-icon APP: prints the path of a 72 px PNG of the icon
      # macOS shows for the app bundle at APP, drawn the first time it is asked
      # for and kept in $RUNTIME_DIRECTORY.
      image=''${RUNTIME_DIRECTORY:?}/icons/$(basename "$1" .app).png
      if [[ ! -s $image ]]; then
        mkdir --parents "$(dirname "$image")"
        /usr/bin/osascript -l JavaScript ${./app-icon.js} "$1" "$image.full.png"
        /usr/bin/sips --resampleHeightWidthMax 72 "$image.full.png" --out "$image" >/dev/null
        rm --force "$image.full.png"
      fi
      printf '%s\n' "$image"
    '';
  });

  # An app's own icon, as the `icon` and `iconCommand` of a button. The
  # app bundles live outside the store, so the Breeze `fallback` shows until
  # the command has drawn the app's icon, once per app. The icon cannot
  # change while deckmaster runs, so the command runs once an hour after that.
  appIcon = app: fallback: {
    icon = fallback;
    iconCommand = run "app-icon-${scriptName app}" ''
      exec ${appIconScript} ${lib.escapeShellArg app}
    '';
    interval = 3600 * 1000;
  };

  # macOS has no mic mute key, so a tap takes the input volume to 0 and the
  # next one brings back the level it had.
  micMute = run "mic-mute" ''
    state=''${RUNTIME_DIRECTORY:?}/mic-volume
    volume=$(/usr/bin/osascript -e 'input volume of (get volume settings)')
    if ((volume > 0)); then
      /bin/mkdir -p "$RUNTIME_DIRECTORY"
      printf '%s\n' "$volume" > "$state"
      /usr/bin/osascript -e 'set volume input volume 0'
    else
      /usr/bin/osascript -e "set volume input volume $(/bin/cat "$state" 2>/dev/null || echo 75)"
    fi
  '';

  # Clokkr's flake builds for Linux only; the Mac runs Clokkr.app, whose
  # bundle carries the CLI.
  clokkr = pkgs.writeShellScriptBin "clokkr" ''
    exec /Applications/Clokkr.app/Contents/MacOS/clokkr "$@"
  '';
in {
  imports = [../../../../../modules/home/programs/deckmaster];

  programs.deckmaster.decks = import ./decks.nix {
    inherit deck launch appIcon micMute;
    clokkrKey = deck.clokkrKey {
      inherit clokkr;
      placeholder = deck.icon "actions/22/chronometer";
    };
  };
}
