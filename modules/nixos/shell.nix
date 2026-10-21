# psoldunov's login shell on every NixOS host but PiHome: zsh, with fish
# still installed. The per-user shell config comes from Home Manager
# (modules/home/shell).
{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    # Home Manager's ~/.zshrc runs compinit itself. A second run from
    # /etc/zshrc only slows every new shell down.
    enableGlobalCompInit = false;
  };
  programs.fish.enable = true;

  users.users.psoldunov.shell = pkgs.zsh;
}
