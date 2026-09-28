# Solaar: the MX Master 3S thumb button opens KWin's Overview, Plasma's
# answer to Mission Control.
#
# Two halves. The rule in rules.yaml fires on the button and asks
# kglobalaccel to run the Overview shortcut, so it works whatever key the
# shortcut is bound to. The rule only sees the button once it is diverted
# (sends HID++ notifications to Solaar instead of acting on its own), and
# that switch lives in config.yaml next to state Solaar owns: battery,
# config cookie, every other setting. Solaar reads config.yaml once at
# startup and rewrites the whole file from memory, so it cannot be a store
# link and an edit made while Solaar runs is lost. The launcher below flips
# the divert in place and then starts Solaar, which applies it to the mouse.
#
# rules.yaml is a store link, so saving from Solaar's rule editor fails.
# Change the rule here instead. Solaar's GUI toggle for the divert still
# works, but the next login sets it back.
{
  lib,
  osConfig,
  pkgs,
  ...
}: let
  solaar = lib.getExe osConfig.programs.solaar.package;

  # The name Solaar stores the mouse under, and the control id of its thumb
  # button ("Mouse Gesture Button" in Solaar).
  device = "MX Master 3S";
  thumbButton = 195;

  overview = [
    "${osConfig.systemd.package}/bin/busctl"
    "--user"
    "call"
    "org.kde.kglobalaccel"
    "/component/kwin"
    "org.kde.kglobalaccel.Component"
    "invokeShortcut"
    "s"
    "Overview"
  ];

  # Never keeps Solaar from starting: a config it cannot read or a mouse it
  # has not seen yet only prints a note.
  launcher =
    pkgs.writers.writePython3 "solaar-launch" {
      libraries = [pkgs.python3Packages.pyyaml];
      flakeIgnore = ["E501"];
    } ''
      import os
      import sys

      import yaml

      SOLAAR = "${solaar}"
      DEVICE = ${builtins.toJSON device}
      KEY = ${toString thumbButton}
      DIVERTED = 1
      CONFIG = os.path.join(
          os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"),
          "solaar",
          "config.yaml",
      )


      def divert(config):
          """Return config with the key diverted, or None if nothing changes."""
          found = False
          changed = False
          patched = [config[0]]
          for entry in config[1:]:
              if isinstance(entry, dict) and entry.get("_NAME") == DEVICE:
                  found = True
                  keys = entry.get("divert-keys") or {}
                  if keys.get(KEY) != DIVERTED:
                      keys = {**keys, KEY: DIVERTED}
                      entry = {**entry, "divert-keys": keys}
                      changed = True
              patched.append(entry)
          if not found:
              print(f"solaar-launch: no {DEVICE} in {CONFIG} yet", file=sys.stderr)
          return patched if changed else None


      def patch():
          with open(CONFIG) as config_file:
              config = yaml.safe_load(config_file)
          if not isinstance(config, list) or not config:
              print(f"solaar-launch: {CONFIG} is empty", file=sys.stderr)
              return
          patched = divert(config)
          if patched is None:
              return
          temporary = CONFIG + ".tmp"
          with open(temporary, "w") as config_file:
              yaml.safe_dump(
                  patched, config_file, default_flow_style=None, width=150
              )
          os.replace(temporary, CONFIG)


      try:
          patch()
      except FileNotFoundError:
          print(f"solaar-launch: no {CONFIG} yet", file=sys.stderr)
      except Exception as error:
          print(f"solaar-launch: left {CONFIG} alone: {error}", file=sys.stderr)

      os.execv(SOLAAR, [SOLAAR, *sys.argv[1:]])
    '';
in {
  xdg.configFile = {
    "solaar/rules.yaml".text = ''
      %YAML 1.3
      ---
      - Key: [Mouse Gesture Button, pressed]
      - Execute: ${builtins.toJSON overview}
      ...
    '';

    # Named like the entry Solaar's own "Launch at login" writes; see
    # ../xdg/autostart.nix for why `force` is set.
    "autostart/solaar.desktop" = {
      source = "${pkgs.makeDesktopItem {
        name = "solaar";
        desktopName = "Solaar";
        icon = "solaar";
        exec = "${launcher} --window=hide";
        terminal = false;
      }}/share/applications/solaar.desktop";
      force = true;
    };
  };
}
