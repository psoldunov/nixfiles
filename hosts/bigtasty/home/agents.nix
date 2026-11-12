# The workstations' agent setup (../../../modules/home/workstation), for
# agents run on BigTasty.
# Claude Code, its MCP servers, skills and rules already come from
# ../../../modules/home on every host. Left out: Mailspring's MCP server and
# Clokkr (desktop apps), Concierge (Whopper's), and the workstation SSH keys
# (BigTasty has its own GitHub key).
{...}: {
  imports = [
    ../../../modules/home/workstation/cli.nix
    # Only the headless server: the Chrome-profile ones need a Chrome.
    ../../../modules/home/workstation/playwright.nix
  ];

  # The package is installed system-wide (../modules/packages.nix).
  programs.codex.enable = true;
  programs.pi-coding-agent.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
