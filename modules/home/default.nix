# Shared home-manager modules. Imported by every host.
{...}: {
  imports = [
    ./git/git.nix
    ./shell/shell.nix
    ./nix-index.nix
    ./sops.nix
    ./programs/claude-code
  ];
}
