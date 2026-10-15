# BigKing's home: the shared modules, nothing of its own yet.
{...}: {
  imports = [
    ../../../modules/home
  ];

  # Preamble + SHELL_SECRETS live in modules/home/sops.nix. BigKing has no
  # secrets file of its own, so it reads the shared one.
  sops.defaultSopsFile = ../../../secrets/shared.yaml;

  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  home.stateVersion = "26.11";
}
