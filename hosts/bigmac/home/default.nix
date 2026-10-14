# BigMac's home-manager config: the shared modules and the workstation layer
# make shell, Claude Code and pi the same as on Whopper; the rest is
# macOS-specific.
{
  inputs,
  lib,
  ...
}: let
  cavemanStatusline = ''bash "${inputs.caveman}/src/hooks/caveman-statusline.sh"'';
in {
  imports = [
    # Shared modules
    ../../../modules/home
    ../../../modules/home/workstation

    # BigMac-local modules
    ./packages.nix
    ./mise.nix
  ];

  # Preamble lives in modules/home/sops.nix. Every secret BigMac's user
  # needs (SHELL_SECRETS, SSH keys, MCP tokens) names secrets/shared.yaml
  # itself, so this file only serves as the fallback.
  sops.defaultSopsFile = ../../../secrets/shared.yaml;

  # Token Station comes from the psoldunov/tap cask here (its flake is
  # Linux-only), so this repeats what its home-manager module does on
  # Whopper (hosts/whopper/home/programs/token-station.nix): the statusline
  # feeds it live plan usage and passes the caveman statusline through.
  # Same priority as that module, so it outranks settings.nix's statusLine.
  programs.claude-code.settings.statusLine = lib.mkOverride 90 {
    type = "command";
    command = "/opt/homebrew/bin/token-station statusline --wrap ${lib.escapeShellArg cavemanStatusline}";
  };

  programs.home-manager.enable = true;

  home.stateVersion = "25.11";
}
