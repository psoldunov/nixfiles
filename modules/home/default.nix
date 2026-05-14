# Shared home-manager modules. Imported by every host.
{...}: {
  imports = [
    ./git/git.nix
    ./shell/shell.nix
    ./programs/claude-code
  ];
}
