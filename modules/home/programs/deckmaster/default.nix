# Deckmaster — drives an Elgato Stream Deck from decks declared in Nix, as a
# systemd user service on Linux (Whopper) and a launchd agent on macOS
# (BigMac). The package is the psoldunov/deckmaster fork (the `deckmaster`
# flake input), which adds the macOS port and what the decks rely on:
# `iconCommand`, `repeat`, and the `toggle` and `temp` widgets.
#
# A host imports this module, sets `programs.deckmaster.decks` and builds its
# keys with ./lib.nix. Each page is written in deckmaster's own TOML schema
# (https://github.com/psoldunov/deckmaster#configuration), so the README maps
# one-to-one onto the Nix. Every page is rendered into a single store
# directory, which keeps page switches (`action.deck = "system.deck"`)
# relative, and the service points at that directory, so a layout change is a
# new service and the switch restarts the daemon.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  package = inputs.deckmaster.packages.${pkgs.stdenv.hostPlatform.system}.default;

  toml = pkgs.formats.toml {};
  deckDir = pkgs.linkFarm "deckmaster-decks" (lib.mapAttrsToList (name: deck: {
      name = "${name}.deck";
      path = toml.generate "${name}.deck" deck;
    })
    config.programs.deckmaster.decks);

  command = [
    (lib.getExe package)
    "-deck"
    "${deckDir}/main.deck"
    "-brightness"
    "70"
    "-sleep"
    "30m"
  ];
in {
  options.programs.deckmaster.decks = lib.mkOption {
    type = lib.types.attrsOf toml.type;
    description = ''
      Stream Deck pages, each becoming <name>.deck in deckmaster's TOML
      schema. deckmaster opens `main` first.
    '';
  };

  config = lib.mkMerge [
    {home.packages = [package];}

    # The system side lives in hosts/whopper/modules/hardware.nix: a udev rule
    # grants the seat user the device, links it as /dev/streamdeck and starts
    # this unit on hotplug. The user sits in the `uinput` group for key
    # emulation. The unit only runs inside the graphical session, so launched
    # apps get its display.
    #
    # On unplug the daemon exits with an error and the restart is skipped by
    # the ExecCondition, so the unit goes quiet instead of failing in a loop.
    (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      systemd.user.services.deckmaster = {
        Unit = {
          Description = "Deckmaster Stream Deck daemon";
          Documentation = "https://github.com/psoldunov/deckmaster";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
          # The udev rule wants this unit as soon as the user manager sees the
          # deck, which at login is before Plasma has pushed WAYLAND_DISPLAY and
          # DISPLAY into the manager. A daemon started then hands every `exec`
          # a display-less environment, and kstart aborts. Requisite fails that
          # early start instead; WantedBy starts the daemon once the session is up.
          Requisite = ["graphical-session.target"];
        };

        Service = {
          ExecCondition = "${pkgs.coreutils}/bin/test -e /dev/streamdeck";
          ExecStart = lib.concatStringsSep " " command;
          # SIGHUP makes deckmaster re-read the current deck file.
          ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
          # The usage, weather and Clokkr keys keep the images they draw in
          # $RUNTIME_DIRECTORY, which systemd removes when the daemon stops. The
          # pomodoro key keeps its own under $XDG_RUNTIME_DIR, so a running timer
          # outlives a restart.
          RuntimeDirectory = "deckmaster";
          Restart = "on-failure";
          RestartSec = 2;
        };

        Install.WantedBy = ["graphical-session.target"];
      };
    })

    # macOS needs no device rules. The agent starts at login and launchd
    # starts it again whenever it exits, at most every 10 s, which also picks
    # the deck up after it is plugged back in. It runs the binary itself,
    # since that binary is what macOS grants Accessibility to (see the host's
    # deckmaster module). The keys keep the images they draw in
    # RUNTIME_DIRECTORY, which launchd does not create, so the scripts do.
    (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      launchd.agents.deckmaster = {
        enable = true;
        config = {
          ProgramArguments = command;
          EnvironmentVariables.RUNTIME_DIRECTORY = "${config.home.homeDirectory}/Library/Caches/deckmaster";
          RunAtLoad = true;
          KeepAlive = true;
          ThrottleInterval = 10;
          ProcessType = "Interactive";
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/deckmaster.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/deckmaster.log";
        };
      };
    })
  ];
}
