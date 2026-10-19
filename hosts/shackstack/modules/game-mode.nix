# Gaming Mode: Valve's gamescope session from Jovian-NixOS (the module is
# imported in flake.nix). It autologins into Steam on boot; Steam's "Switch
# to Desktop" goes to Plasma (./desktop.nix) and the "Return to Gaming Mode"
# launcher there comes back.
#
# HDR, VRR and the 4K@120 mode are Steam's own display settings. Valve's
# session script already advertises them (STEAM_GAMESCOPE_HDR_SUPPORTED,
# STEAM_GAMESCOPE_VRR_SUPPORTED), so gamescope needs no flags here.
{pkgs, ...}: {
  jovian.steam = {
    enable = true;
    autoStart = true;
    user = "psoldunov";
    desktopSession = "plasma";
    # Our own units drive CEC (./tv-cec). Valve's session turns on Steam's
    # CEC settings page, which talks to cecd; with cecd off it would show
    # switches that do nothing.
    environment.STEAM_ENABLE_CEC = "0";
  };

  # Early amdgpu KMS (for Plymouth) and the brightness rule. The Deck-only
  # parts (jovian.devices.steamdeck) stay off by default.
  jovian.hardware.has.amd.gpu = true;

  # useSteamOSConfig (on with jovian.steam) would start Valve's cecd. Bazzite
  # warns it fights external adapters for wake-up, and ./tv-cec owns CEC.
  jovian.steamos.enableHdmiCecIntegration = false;

  # Fresh install, nothing carried over from Bazzite. Plugins come from the
  # Decky store (SteamGridDB). Decky also needs Steam's CEF remote
  # debugging, switched on in ../home/default.nix.
  jovian.decky-loader.enable = true;

  # Jovian sets programs.steam.enable and the package; these add to it.
  programs.steam = {
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraCompatPackages = [pkgs.proton-ge-bin];
    protontricks.enable = true;
  };

  # Jovian turns on scx_lavd (mkDefault) for steamos-manager to start. Off
  # here: the i5-12600K has P- and E-cores, and LAVD kept moving Sniper
  # Elite Resistance's audio mixing thread onto the E-cores, where it could
  # not keep up and the sound crackled. The kernel's own scheduler keeps
  # busy threads on the P-cores, as on Whopper (i9-12900K, also hybrid).
  services.scx.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  # PipeWire asks RTKit for realtime priority on its audio threads. Without
  # it they run as ordinary tasks, and a game loading every core starves
  # them: Sniper Elite Resistance stuttered with xruns on the HDMI sink.
  # Whopper sets this in hosts/whopper/modules/security.nix.
  security.rtkit.enable = true;

  # DualSense and two Xbox Wireless pads over the AX211. Steam Input reads
  # them through hidraw, so no xpadneo; Bazzite ran without it too. Jovian
  # applies SteamOS's BlueZ settings.
  hardware.bluetooth.powerOnBoot = true;
  # Logitech Unifying receiver (K400 Plus, MX Master 3).
  hardware.logitech.wireless.enable = true;

  # Wake from suspend with a controller: the AX211's Bluetooth function
  # (8087:0033) and the xHCI controller it hangs off must both allow wakeup.
  # ./pad-wake keeps the controller connected once the system is up.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="xhci_hcd", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="8087", ATTR{idProduct}=="0033", ATTR{power/wakeup}="enabled"
  '';
}
