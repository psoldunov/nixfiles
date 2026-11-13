# What every Mac's home-manager config shares on top of ../ and
# ../workstation: the extra CLI set, mise runtimes, Syncthing and Token
# Station. Imported by hosts/bigmac/home and hosts/macflurry/home.
{
  config,
  inputs,
  lib,
  ...
}: let
  # The cask installs only the app, with no link in /opt/homebrew/bin, so
  # the CLI is called inside the bundle.
  tokenStation = "/Applications/Token Station.app/Contents/MacOS/token-station";
in {
  imports = [
    ./mise.nix
    ./packages.nix
    ./syncthing.nix
    inputs.mail-app-mcp.homeManagerModules.default
  ];

  # Shared programs.mcp feeds Claude Code, Codex and pi. Mail must be open;
  # macOS asks the launcher for Automation permission on first use.
  services.mail-app-mcp.enable = true;

  # Codex's mutable merge preserves servers removed from Nix declarations.
  home.activation.removeMailspringMcp = lib.hm.dag.entryAfter ["codexMutableSettings"] ''
    run env CODEX_HOME=${lib.escapeShellArg "${config.home.homeDirectory}/.codex"} /opt/homebrew/bin/codex mcp remove mailspring
  '';

  # Preamble lives in ../sops.nix. Every secret a Mac's user needs
  # (SHELL_SECRETS, SSH keys, MCP tokens) names secrets/shared.yaml itself,
  # so this only serves as the fallback.
  sops.defaultSopsFile = ../../../secrets/shared.yaml;

  # Token Station comes from the psoldunov/tap cask here (its flake is
  # Linux-only), so this repeats what its home-manager module does on
  # Whopper (hosts/whopper/home/programs/token-station.nix): the statusline
  # feeds it live plan usage.
  programs.claude-code.settings.statusLine = {
    type = "command";
    command = "${lib.escapeShellArg tokenStation} statusline";
  };

  programs.home-manager.enable = true;
}
