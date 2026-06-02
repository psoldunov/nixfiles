# BigTasty-local NixOS modules. Shared baseline (boot loader, locale,
# nix settings, users, sops preamble, virtualisation, fwupd, …) is
# pulled in via ../../../modules/nixos.
{...}: {
  imports = [
    ../../../modules/nixos

    ./boot.nix
    ./filesystems.nix
    ./hardware.nix
    ./networking.nix
    ./nix-locale.nix
    ./packages.nix
    ./services-cloudflare.nix
    ./services-media.nix
    ./services-misc.nix
    ./services-shares.nix
    ./services-web.nix
    ./sops.nix
    ./users.nix
    ./virtualisation.nix

    ./services/immich.nix
    ./services/infisical.nix
    ./services/karakeep.nix
    ./services/n8n.nix
    ./services/nocodb.nix
    ./services/paperless.nix
    ./services/sotf-server.nix
    ./services/syncthing.nix
    ./services/vaultwarden.nix
  ];
}
