# What every Mac's home-manager config shares on top of ../ and
# ../workstation: the extra CLI set, mise runtimes, Syncthing and Token
# Station. Imported by hosts/bigmac/home and hosts/macflurry/home.
{
  inputs,
  lib,
  ...
}: let
  cavemanStatusline = ''bash "${inputs.caveman}/src/hooks/caveman-statusline.sh"'';
  # The cask installs only the app, with no link in /opt/homebrew/bin, so
  # the CLI is called inside the bundle.
  tokenStation = "/Applications/Token Station.app/Contents/MacOS/token-station";
in {
  imports = [
    ./mise.nix
    ./packages.nix
    ./syncthing.nix
  ];

  # Preamble lives in ../sops.nix. Every secret a Mac's user needs
  # (SHELL_SECRETS, SSH keys, MCP tokens) names secrets/shared.yaml itself,
  # so this only serves as the fallback.
  sops.defaultSopsFile = ../../../secrets/shared.yaml;

  # Token Station comes from the psoldunov/tap cask here (its flake is
  # Linux-only), so this repeats what its home-manager module does on
  # Whopper (hosts/whopper/home/programs/token-station.nix): the statusline
  # feeds it live plan usage and passes the caveman statusline through.
  # Same priority as that module, so it outranks settings.nix's statusLine.
  programs.claude-code.settings.statusLine = lib.mkOverride 90 {
    type = "command";
    command = "${lib.escapeShellArg tokenStation} statusline --wrap ${lib.escapeShellArg cavemanStatusline}";
  };

  programs.home-manager.enable = true;
}
