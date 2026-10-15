# The AS6604T's own hardware: case fan, front panel LEDs, USB copy button
# and LCD. The kernel drivers come from mafredri/asustor-platform-driver,
# which supports the AS66xx boards (DMI Insyde/GeminiLake) but lists them
# as untested; INSTALL.md says what to check on the first boot.
{
  inputs,
  lib,
  pkgs,
  ...
}: let
  script = name: file:
    lib.getExe (pkgs.writeShellApplication {
      inherit name;
      text = builtins.readFile file;
    });

  openlcmd = pkgs.callPackage ./openlcmd.nix {src = inputs.lcm;};
in {
  imports = [
    inputs.asustor-platform-driver.nixosModules.default
  ];

  # asustor (LEDs, USB copy button), asustor_it87 (sensors, fan PWM) and
  # asustor_gpio_it87. asustor loads the other two itself (softdep). The
  # mainline it87 drivers claim the same Super I/O chip, so keep them out.
  hardware.asustor.enable = true;
  boot.blacklistedKernelModules = ["it87" "gpio_it87"];
  # The Super I/O registers sit in an I/O range ACPI also claims.
  boot.kernelParams = ["acpi_enforce_resources=lax"];
  # drivetemp: HDD temperatures as hwmon devices, for the fan.
  # ledtrig_netdev: the LAN LED's trigger.
  boot.kernelModules = ["asustor" "drivetemp" "ledtrig_netdev"];

  systemd.services.asustor-fan = {
    description = "Case fan control from disk and CPU temperatures";
    wantedBy = ["multi-user.target"];
    after = ["systemd-modules-load.service"];
    # A starting curve; tune it against `sensors` once the box runs.
    environment = {
      DISK_MIN = "35";
      DISK_MAX = "50";
      CPU_MIN = "55";
      CPU_MAX = "85";
      MIN_PWM = "80";
      INTERVAL = "10";
    };
    serviceConfig = {
      ExecStart = script "asustor-fan" ./fan.sh;
      Restart = "always";
      RestartSec = 10;
    };
  };

  systemd.services.asustor-leds = {
    description = "Front panel LED triggers";
    wantedBy = ["multi-user.target"];
    after = ["systemd-modules-load.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = script "asustor-leds" ./leds.sh;
    };
  };

  # It reads the IP address once, at start.
  systemd.services.openlcmd = {
    description = "Front LCD (hostname and IP address)";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target"];
    serviceConfig = {
      ExecStart = "${lib.getExe openlcmd} -systemd";
      Restart = "on-failure";
      RestartSec = 5;
      DynamicUser = true;
      # /dev/ttyS1 is root:dialout.
      SupplementaryGroups = ["dialout"];
    };
  };
}
