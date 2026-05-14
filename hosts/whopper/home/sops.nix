# Preamble + SHELL_SECRETS live in modules/home/sops.nix.
{...}: {
  sops.defaultSopsFile = ../../../secrets/whopper.yaml;
}
