# KWin window rules that remember per-app window state across restarts.
#
# Under Wayland an app cannot place its own window, so without a rule every
# launch lands wherever KWin's placement policy puts it. A "Remember" rule makes
# KWin apply the last state at map time and save the state again on close. This
# covers the window position, the window size, and Keep Above Others (the toggle
# in the task manager's "More" menu).
#
# Each rule declares only the policy keys (positionrule, sizerule, aboverule).
# KWin writes the remembered values (position=, size=, above=) back into
# ~/.config/kwinrulesrc itself. plasma-manager merges only the keys declared
# here, so a rebuild keeps those values. programs.plasma.window-rules is not
# used because it always writes a value next to each policy, and that resets
# the saved geometry on every rebuild.
#
# NOTE: this owns [General] rules= in kwinrulesrc. A rule added in System
# Settings > Window Management > Window Rules drops out of that list on the next
# rebuild, so add it here instead.
{
  lib,
  pkgs,
  ...
}: let
  # KWin rule policy, from kwin/src/rules.h.
  remember = 4;
  # Match only normal windows, so an app's dialogs keep default placement and
  # do not overwrite the main window's saved geometry.
  normalWindows = 1;

  # Window class (resourceClass) of each app. System Settings > Window Rules >
  # Add New > Detect Window Properties shows it for any open window.
  rememberedApps = [
    "plexamp"
  ];

  groupName = class: "remember-${class}";

  mkRule = class: {
    Description = "Remember position, size and Keep Above for ${class}";
    wmclass = class;
    wmclassmatch = 1; # exact
    types = normalWindows;
    positionrule = remember;
    sizerule = remember;
    aboverule = remember;
  };

  dbusSend = "${pkgs.dbus}/bin/dbus-send";
in {
  programs.plasma.configFile.kwinrulesrc =
    {
      General = {
        count = lib.length rememberedApps;
        rules = lib.concatMapStringsSep "," groupName rememberedApps;
      };
    }
    // lib.listToAttrs (map (class: lib.nameValuePair (groupName class) (mkRule class)) rememberedApps);

  # KWin keeps its rule book in memory. When a remembered window closes, KWin
  # rewrites kwinrulesrc from memory, which drops rules it has not loaded yet.
  # So tell KWin to reread the file right after plasma-manager writes it. Skip
  # this when no Plasma session is running (for example, a rebuild from a TTY).
  home.activation.reloadKwinRules = lib.hm.dag.entryAfter ["configure-plasma"] ''
    bus="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/bus}"
    if ${dbusSend} --bus="$bus" --print-reply --dest=org.freedesktop.DBus / \
        org.freedesktop.DBus.NameHasOwner string:org.kde.KWin 2>/dev/null \
        | ${pkgs.gnugrep}/bin/grep -q 'boolean true'; then
      $DRY_RUN_CMD ${dbusSend} --bus="$bus" --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure
    fi
  '';
}
