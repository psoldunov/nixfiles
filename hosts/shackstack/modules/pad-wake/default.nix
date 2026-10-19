# Waking ShackStack with a controller. The kernel can lose the controller's
# first packet on resume, and the controller then switches itself off a few
# seconds after waking the system. After every resume this finishes the
# connection from ShackStack's side; ./pad-wake.sh explains the race. The
# wakeup switches for the AX211 are in ../game-mode.nix.
{
  config,
  pkgs,
  ...
}: let
  shackstack-pad-wake = pkgs.writeShellApplication {
    name = "shackstack-pad-wake";
    runtimeInputs = [config.hardware.bluetooth.package pkgs.coreutils pkgs.gawk pkgs.gnugrep];
    text = builtins.readFile ./pad-wake.sh;
  };

  # Every sleep mode systemd has, as in ../tv-cec.
  sleepTargets = ["suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target"];
in {
  environment.systemPackages = [shackstack-pad-wake];

  # After= a sleep target orders it behind the wake-up, and WantedBy= one
  # starts it then. Not at boot: no controller has woken anything.
  systemd.services.shackstack-pad-wake = {
    description = "Finish connecting the Bluetooth controller that woke ShackStack";
    wantedBy = sleepTargets;
    after = sleepTargets;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${shackstack-pad-wake}/bin/shackstack-pad-wake";
      TimeoutStartSec = 30;
    };
  };
}
