# T3 Code's server, so Whopper's desktop app can run agents here. It is the
# nightly Whopper runs (overlays/t3code/pin.json): rebuild both hosts after
# `update_t3code`, or the app refuses to connect.
#
# It listens on loopback only. Connect from Whopper with Settings →
# Environments → Add environment → SSH → `bigtasty`. The desktop's SSH
# launcher adopts the server already running in ~/.t3 (it reads
# ~/.t3/userdata/server-runtime.json) and forwards its port, so no firewall
# port or pairing link is needed. The launcher still downloads its own `t3`
# into ~/.t3/runtime once per version, for the helpers it runs.
#
# Agents use the provider CLIs installed here and their logins here (run
# `claude auth login` on BigTasty once).
{
  config,
  lib,
  pkgs,
  ...
}: let
  user = "psoldunov";
  home = config.users.users.${user}.home;
in {
  # A system unit rather than a user one: a rebuild restarts it when the
  # package changes, so the server moves to the new pin with Whopper.
  systemd.services.t3code-server = {
    description = "T3 Code server";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target"];
    # NixOS gives units a PATH of coreutils and friends. Agents need the
    # user's profile: claude, git, node, nix.
    environment.PATH = lib.mkForce (lib.concatStringsSep ":" [
      "/run/wrappers/bin"
      "${home}/.local/bin"
      "${home}/.nix-profile/bin"
      "/etc/profiles/per-user/${user}/bin"
      "/nix/var/nix/profiles/default/bin"
      "/run/current-system/sw/bin"
    ]);
    serviceConfig = {
      User = user;
      Group = "users";
      WorkingDirectory = home;
      # Without --host it listens on every interface.
      ExecStart = "${lib.getExe pkgs.t3code-server-nightly} serve --host 127.0.0.1";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
