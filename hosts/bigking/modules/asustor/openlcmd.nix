# openlcmd, from mafredri/lcm: a reimplementation of ADM's LCD daemon. It
# shows the hostname and IP address on the front LCD (/dev/ttyS1) and has
# a small menu on its buttons.
{
  lib,
  buildGoModule,
  src,
}:
buildGoModule {
  pname = "openlcmd";
  version = "0-unstable-2022-12-29";
  inherit src;

  # go.mod still says 1.16, but its golang.org/x/sys uses unsafe.Slice (1.17).
  # From 1.17 on, Go wants the indirect requirements listed: these two are
  # what `go mod tidy -go=1.17` adds.
  #
  # openlcmd never switches the display on, so it writes to a dark screen
  # whenever something else (ADM's lcmd on its way out) left it off, and it
  # switches the screen off itself after 15 s without a button press. Turn
  # it on with every redraw of the home screen, and leave it on when idle.
  postPatch = ''
    substituteInPlace go.mod --replace-fail "go 1.16" "go 1.17"
    cat >>go.mod <<EOF

    require (
    	github.com/go-ole/go-ole v1.2.6 // indirect
    	github.com/yusufpapurcu/wmi v1.2.2 // indirect
    )
    EOF

    substituteInPlace cmd/openlcmd/main.go --replace-fail \
      'setDisplay(mon, lcm.DisplayTop, 0, hostname)' \
      'send(mon, lcm.DisplayOn); send(mon, lcm.DisplayStatus); setDisplay(mon, lcm.DisplayTop, 0, hostname)'
    substituteInPlace cmd/openlcmd/monitor/monitor.go --replace-fail \
      'm.send(lcm.DisplayOff)' 'm.send(lcm.DisplayOn)'
  '';

  vendorHash = "sha256-TMk/wEn2TKG0OC9doiUURoGansq/PfmMFcIqKYLr0Cc=";
  subPackages = ["cmd/openlcmd"];

  meta = {
    description = "Daemon for the front LCD of ASUSTOR NAS devices";
    homepage = "https://github.com/mafredri/lcm";
    license = lib.licenses.mit;
    mainProgram = "openlcmd";
    platforms = lib.platforms.linux;
  };
}
