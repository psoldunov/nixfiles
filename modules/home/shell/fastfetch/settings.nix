# The fastfetch config. On the left a pseudo-3D logo (logos/): the rainbow
# Apple on the Macs, the NixOS snowflake everywhere else. On the right one
# rounded rail, split into sections whose accents come from the logo.
# Desktops get a desktop section; servers get the load average instead.
#
# A plain function of lib and two flags, so it can be rendered without
# home-manager:
#   nix eval --json --impure --expr 'import ./settings.nix {
#     lib = (import <nixpkgs> {}).lib; isDarwin = true; isDesktop = true; }'
{
  lib,
  isDarwin,
  isDesktop,
}: let
  # A Nerd Font glyph from its hex codepoint. Spelled as codepoints so this
  # file stays plain ASCII: editors and tools tend to drop private-use
  # characters. Codepoints above U+FFFF go through a JSON surrogate pair.
  glyph = hex: let
    cp = lib.fromHexString hex;
    u = n: "\\u" + lib.fixedWidthString 4 "0" (lib.toHexString n);
    v = cp - 65536;
    escaped =
      if cp < 65536
      then u cp
      else u (55296 + v / 1024) + u (56320 + lib.mod v 1024);
  in
    builtins.fromJSON ''"${escaped}"'';

  icons = lib.mapAttrs (_: glyph) {
    apple = "F179"; # fa-apple
    nixos = "F313"; # linux-nixos
    computer = "F0AAB"; # md-desktop_tower_monitor
    server = "F048B"; # md-server
    cog = "F0493"; # md-cog
    penguin = "F0EC0"; # md-penguin
    uptime = "F0150"; # md-clock_outline
    packages = "F03D6"; # md-package_variant
    shell = "F07B7"; # md-console_line
    network = "F0A60"; # md-ip_network
    cpu = "F0EE0"; # md-cpu_64_bit
    gpu = "F08AE"; # md-expansion_card
    memory = "F035B"; # md-memory
    disk = "F02CA"; # md-harddisk
    battery = "F0079"; # md-battery
    load = "F029A"; # md-gauge
    de = "F056E"; # md-view_dashboard
    wm = "F05AF"; # md-window_maximize
    terminal = "F018D"; # md-console
    font = "F06D6"; # md-format_font
    display = "F0379"; # md-monitor
  };

  theme =
    if isDarwin
    then {
      logo = ./logos/apple.ans;
      osIcon = icons.apple;
      kernelIcon = icons.cog;
      # Stripes of the 1977 rainbow Apple.
      user = "#61BB46";
      host = "#009DDC";
      system = "#61BB46";
      hardware = "#F5821F";
      desktop = "#009DDC";
    }
    else {
      logo = ./logos/nixos.ans;
      osIcon = icons.nixos;
      kernelIcon = icons.penguin;
      # The snowflake's two blues, plus a lavender for the third section.
      user = "#7EBAE4";
      host = "#5277C3";
      system = "#7EBAE4";
      hardware = "#5E86D0";
      desktop = "#A28CE0";
    };

  # Width of the rail's horizontal rules, and of the key labels.
  ruleWidth = 46;
  labelWidth = 9;

  repeat = n: s: lib.concatStrings (lib.genList (_: s) n);
  padRight = width: s: s + repeat (width - lib.stringLength s) " ";

  # `{#<color>}` switches colour inside a fastfetch format string; `{#}` resets.
  paint = color: text: "{#${color}}${text}{#}";
  dim = paint "90";

  # "├─ hardware ──────…", filled out to ruleWidth columns.
  rule = corner: label: color: {
    type = "custom";
    format =
      dim "${corner}─ "
      + "{#1}"
      + paint color label
      + dim " ${repeat (ruleWidth - 4 - lib.stringLength label) "─"}";
  };

  # "│  <icon>  label     value"
  row = color: icon: label: type: extra:
    {
      inherit type;
      key = dim "│" + "  " + paint color "${icon}  ${padRight labelWidth label}";
    }
    // extra;

  # Lines the user and host up with the section labels below.
  title = {
    type = "title";
    format = "   {#1}" + paint theme.user "{user-name}" + dim "@" + "{#1}" + paint theme.host "{host-name}";
  };

  # The bottom corner doubles as a strip of the terminal's palette.
  footer = {
    type = "custom";
    format =
      dim "╰─ "
      + lib.concatMapStrings (c: paint c "● ") ["31" "32" "33" "34" "35" "36"]
      + dim (repeat (ruleWidth - 15) "─");
  };

  system = let
    c = theme.system;
  in [
    (rule "╭" "system" c)
    (row c theme.osIcon "os" "os" {})
    (row c (
      if isDesktop
      then icons.computer
      else icons.server
    ) "host" "host" {})
    (row c theme.kernelIcon "kernel" "kernel" {})
    (row c icons.uptime "uptime" "uptime" {})
    # Total first, then the Nix and Homebrew shares when there are any.
    (row c icons.packages "packages" "packages" {
      format = "{all}{?nix-all}  " + dim "nix {nix-all}" + "{?}{?brew-all}  " + dim "brew {brew-all}" + "{?}";
    })
    (row c icons.shell "shell" "shell" {})
    (row c icons.network "network" "localip" {
      format = "{ipv4}  " + dim "{ifname}";
    })
  ];

  hardware = let
    c = theme.hardware;
  in
    [
      (rule "├" "hardware" c)
      (row c icons.cpu "cpu" "cpu" {})
      (row c icons.gpu "gpu" "gpu" {})
      (row c icons.memory "memory" "memory" {
        format = "{percentage-bar} {percentage}  {used} / {total}";
      })
      (row c icons.disk "disk" "disk" {
        format = "{size-percentage-bar} {size-percentage}  {size-used} / {size-total}  " + dim "{mountpoint}";
      })
      # Laptops only; fastfetch drops modules that find nothing.
      (row c icons.battery "battery" "battery" {
        format = "{capacity-bar} {capacity}  " + dim "{status}";
      })
    ]
    ++ lib.optional (!isDesktop) (row c icons.load "load" "loadavg" {});

  desktop = let
    c = theme.desktop;
  in [
    (rule "├" "desktop" c)
    # Plasma on Whopper; macOS reports no DE and the row drops out.
    (row c icons.de "desktop" "de" {})
    (row c icons.wm "wm" "wm" {})
    (row c icons.terminal "terminal" "terminal" {})
    (row c icons.font "font" "terminalfont" {})
    (row c icons.display "display" "display" {
      format = "{width}x{height} @ {refresh-rate} Hz";
    })
  ];
in {
  "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

  logo = {
    type = "file-raw";
    source = "${theme.logo}";
    padding = {
      top = 1;
      left = 2;
      right = 4;
    };
  };

  display = {
    separator = " ";
    color = {
      keys = "90";
      separator = "90";
    };
    # Usage as a coloured number plus a one-colour bar; the bar only shows
    # where a format asks for it with {percentage-bar}.
    percent = {
      type = ["num" "num-color" "bar" "bar-monochrome"];
      width = 3;
    };
    bar = {
      char = {
        elapsed = "━";
        total = "━";
      };
      border = null;
      width = 12;
      color.total = "90";
    };
  };

  modules =
    [title]
    ++ system
    ++ hardware
    ++ lib.optionals isDesktop desktop
    ++ [footer];
}
