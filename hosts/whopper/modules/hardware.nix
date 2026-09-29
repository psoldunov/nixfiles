{
  lib,
  pkgs,
  ...
}: let
  # Stream Deck product IDs that deckmaster's device library drives: original,
  # V2, MK.2, Mini, Mini MK.2 and XL. Elgato's capture cards and mics share the
  # vendor ID, so the rule below names the models instead of matching 0fd9.
  streamDeckProducts = ["0060" "006d" "0080" "0063" "0090" "006c"];
in {
  # NOTE: `boot.initrd.kernelModules = ["amdgpu" ...]` is set in ./boot.nix
  # because it is a boot-time concern, even though the GPU is configured here.
  # `hardware.graphics.enable{,32Bit}` baseline is in modules/nixos/hardware.nix.
  hardware.graphics = {
    extraPackages = with pkgs; [
      libva
      libva-vdpau-driver
      vdpauinfo
      libvdpau
      libvpx
      libvdpau-va-gl
      libGL
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.libva-vdpau-driver
      driversi686Linux.vdpauinfo
      driversi686Linux.libvdpau-va-gl
    ];
  };

  hardware.amdgpu.opencl.enable = true;

  hardware.keyboard.zsa.enable = true;
  hardware.keyboard.qmk.enable = true;

  hardware = {
    # Disabled: openrazer 3.12.2 fails to build against kernel 6.18 due to
    # hid_report_raw_event API change. Re-enable once nixpkgs ships a patched
    # version (upstream issue tracked at openrazer/openrazer).
    openrazer = {
      enable = false;
      users = ["psoldunov"];
      batteryNotifier.enable = true;
    };
    logitech = {
      wireless = {
        enable = true;
      };
    };
    sane.enable = true;
    bluetooth = {
      enable = true;
    };
    uinput.enable = true;
    xone.enable = true;
    i2c.enable = true;
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "HP_LaserJet_MFP_M28w_9B18D8";
        location = "Office";
        deviceUri = "http://10.24.24.229:631";
        model = "drv:///hp/hpcups.drv/hp-laserjet_pro_mfp_m27cnw.ppd";
        ppdOptions = {
          PageSize = "A4";
        };
      }
    ];
    ensureDefaultPrinter = "HP_LaserJet_MFP_M28w_9B18D8";
  };

  # Solaar, for the Logitech receiver above. This replaces
  # `hardware.logitech.wireless.enableGraphical`, which nixpkgs renamed; the
  # option brings the package, so it is no longer in ./packages.nix. The
  # package is built from the psoldunov/Solaar fork; see overlays/solaar.nix.
  programs.solaar.enable = true;

  # LibrePods, a tray app for AirPods over the Bluetooth adapter above: battery,
  # noise control modes, ear detection and conversational awareness. The option
  # brings the package and a `librepods` wrapper in /run/wrappers/bin that holds
  # cap_net_admin, runnable only by the `librepods` group (see ./users.nix).
  # Launch it through that wrapper, not the store path.
  #
  # Hearing aid features also need `DeviceID = bluetooth:004C:0000:0000` under
  # `hardware.bluetooth.settings.General`, which makes the AirPods drop the
  # connection now and then, so it is left off.
  programs.librepods.enable = true;

  # Elgato Stream Deck, driven by deckmaster from the user session (see
  # ../home/programs/deckmaster). deckmaster opens the USB device through
  # libusb, so the rule targets the usb_device node rather than hidraw. It
  # grants the seat user access, links the deck as /dev/streamdeck and starts
  # the user's deckmaster.service when the deck is plugged in.
  #
  # `uaccess` only takes effect in rules that sort before 73-seat-late.rules,
  # which services.udev.extraRules (99-local.rules) does not, hence a package.
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "streamdeck-udev-rules";
      destination = "/etc/udev/rules.d/70-streamdeck.rules";
      text =
        lib.concatMapStrings (product: ''
          SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="0fd9", ATTR{idProduct}=="${product}", TAG+="uaccess", TAG+="systemd", SYMLINK+="streamdeck", ENV{SYSTEMD_USER_WANTS}+="deckmaster.service"
        '')
        streamDeckProducts;
    })
  ];
}
