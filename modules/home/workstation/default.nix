# What the workstations (Whopper, BigMac, MacFlurry) share on top of ../
# (which BigTasty imports too): the same SSH keys and hosts, CLI tools,
# system scripts, Ghostty config, Claude Code MCP servers and pi. Imported by
# hosts/whopper/home, hosts/bigmac/home and hosts/macflurry/home.
# Platform differences are handled inside each module with
# `pkgs.stdenv.hostPlatform.isDarwin`.
{...}: {
  imports = [
    ./adguard.nix
    ./cli.nix
    ./ghostty.nix
    ./mailspring.nix
    ./playwright.nix
    ./scripts.nix
    ./ssh.nix
  ];

  # Same SHELL_SECRETS on every workstation. BigTasty keeps its own, from
  # its default sops file (modules/home/sops.nix).
  sops.secrets.SHELL_SECRETS.sopsFile = ../../../secrets/shared.yaml;

  # Installs pi and, through ../programs/pi, its claude-bridge extension.
  programs.pi-coding-agent.enable = true;

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    btop.enable = true;
    htop.enable = true;
  };
}
