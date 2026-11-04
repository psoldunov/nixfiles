# T3 Code on the workstations: one server per machine in ~/.t3, shared by the
# local app and by other machines' apps connecting over SSH.
#
# Left alone, the desktop app starts its own server in ~/.t3. When another
# machine's app connects over SSH while the local app is closed, its launcher
# starts a detached server in that same ~/.t3, which outlives the connection.
# Only one server may own a T3 home, so the local app then refuses to open
# ("This T3 home is unavailable"; upstream calls it working as designed,
# pingdotgg/t3code#21423). So a background service owns ~/.t3, SSH launchers
# adopt it, and the app runs with its local environment off as a client of it.
#
# - Whopper: the user service below, pinned to overlays/t3code/pin.json like
#   the app, so a rebuild moves both.
# - BigMac, MacFlurry: upstream's service, installed once per Mac with
#   `~/.t3/bin/t3 service install` (`~/.t3/bin/t3` appears once the app has
#   run). The cask app updates itself; its update button moves the service too.
#
# Pair the app with its own machine once: run
# `~/.t3/bin/t3 auth pairing create --base-url http://127.0.0.1:3773` and paste
# the Pair URL into Settings → Environments → Add environment.
{
  config,
  lib,
  pkgs,
  ...
}: let
  settings = "${config.home.homeDirectory}/.t3/userdata/desktop-settings.json";
  jq = lib.getExe pkgs.jq;
in {
  # The app rewrites this file from the state it loaded, dropping the key when
  # it started with the local environment on (pingdotgg/t3code#26144), so every
  # activation sets it again. Quit the app before switching.
  home.activation.t3codeLocalEnvironmentOff = lib.hm.dag.entryAfter ["writeBoundary"] ''
    settings=${lib.escapeShellArg settings}
    run install -d -m 700 "$(dirname "$(dirname "$settings")")" "$(dirname "$settings")"
    if [[ ! -s "$settings" ]]; then
      [[ -v DRY_RUN ]] || echo '{"localEnvironmentEnabled":false}' >"$settings"
    elif ! ${jq} -e '.localEnvironmentEnabled == false' "$settings" >/dev/null 2>&1; then
      if ${jq} -c '.localEnvironmentEnabled = false' "$settings" >"$settings.hm-tmp"; then
        run mv -f "$settings.hm-tmp" "$settings"
      else
        rm -f "$settings.hm-tmp"
        warnEcho "t3code: $settings is not valid JSON; turn off Local environment in the app"
      fi
    fi
  '';

  systemd.user.services.t3code-server = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Unit = {
      Description = "T3 Code server";
      # Agents get the desktop session's environment (PATH, SSH agent,
      # display), which Plasma imports into the user manager at login.
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      # Otherwise it opens a pairing page in the browser at every start.
      Environment = ["T3CODE_NO_BROWSER=1"];
      ExecStart = "${lib.getExe pkgs.t3code-server-nightly} serve --host 127.0.0.1 --base-dir %h/.t3";
      # Also retries while the app, from before the switch, still owns ~/.t3.
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
