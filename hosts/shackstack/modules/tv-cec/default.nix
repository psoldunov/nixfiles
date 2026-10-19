# The Sony TV follows ShackStack over HDMI-CEC: on and switched to this input
# at boot and after resume, standby before suspend and on power-off. A
# reboot leaves the TV on. The TV remote navigates Steam.
#
# Bazzite shipped the same hooks (cec-control) but they were disabled on
# this box, which is why CEC never seemed to work. Valve's cecd stays off
# (jovian.steamos.enableHdmiCecIntegration in ../game-mode.nix).
#
# Waking the TV from standby needs the adapter's CEC tunnel to stay up while
# the TV sleeps. If it does not, `shackstack-tv on` exits non-zero and the
# TV has to be switched on with its remote; see ../../INSTALL.md.
{pkgs, ...}: let
  shackstack-tv = pkgs.writeShellApplication {
    name = "shackstack-tv";
    runtimeInputs = with pkgs; [v4l-utils coreutils gawk gnugrep];
    text = builtins.readFile ./shackstack-tv.sh;
  };

  # Every sleep mode systemd has, for the resume and sleep hooks.
  sleepTargets = ["suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target"];
in {
  environment.systemPackages = [shackstack-tv pkgs.v4l-utils];

  # amdgpu drops the CEC device a second after hotplug goes low and makes a
  # new, unconfigured one when it comes back. 1000 means never unregister,
  # so /dev/cec0 and its claimed logical address survive TV standby.
  boot.kernelParams = ["drm_display_helper.drm_dp_cec_unregister_delay=1000"];

  services.udev.extraRules = ''
    # psoldunov is in `video`, so cec-ctl works without sudo for testing.
    KERNEL=="cec[0-9]*", GROUP="video", MODE="0660"
    # TV remote keys through the rc-cec device, mapped for Steam. Matched on
    # the input device, as v4l-utils' own 70-infrared.rules does: the rc
    # device appears before its input node, which ir-keytable writes to.
    ACTION=="add", SUBSYSTEM=="input", KERNEL=="event*", SUBSYSTEMS=="rc", ATTRS{protocols}=="*cec*", ENV{.rc_sysdev}="$id", RUN+="${pkgs.v4l-utils}/bin/ir-keytable --sysdev $env{.rc_sysdev} --clear --write ${./steam-remote.toml}"
  '';

  systemd.services = {
    # At boot, and after every resume: After= a sleep target orders it behind
    # the wake-up, and WantedBy= one starts it then.
    shackstack-tv-on = {
      description = "Turn the TV on and switch it to ShackStack (HDMI-CEC)";
      wantedBy = ["multi-user.target"] ++ sleepTargets;
      after = sleepTargets;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${shackstack-tv}/bin/shackstack-tv on";
        TimeoutStartSec = 30;
      };
    };

    # Before the system sleeps, while hotplug is still up.
    shackstack-tv-sleep = {
      description = "Put the TV in standby before ShackStack sleeps (HDMI-CEC)";
      unitConfig.DefaultDependencies = false;
      wantedBy = ["sleep.target"];
      before = ["sleep.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${shackstack-tv}/bin/shackstack-tv standby";
        TimeoutStartSec = 20;
      };
    };

    # On power-off only; reboot.target does not pull it.
    shackstack-tv-poweroff = {
      description = "Put the TV in standby when ShackStack powers off (HDMI-CEC)";
      unitConfig.DefaultDependencies = false;
      wantedBy = ["poweroff.target"];
      before = ["systemd-poweroff.service" "poweroff.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${shackstack-tv}/bin/shackstack-tv standby";
        TimeoutStartSec = 20;
      };
    };
  };
}
