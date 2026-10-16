# BigTasty-local NixOS modules. Shared baseline (boot loader, locale,
# nix settings, users, sops preamble, virtualisation, fwupd, …) is
# pulled in via ../../../modules/nixos.
{...}: {
  imports = [
    ../../../modules/nixos
    ../../../modules/nixos/server-monitoring
    # Standby DNS server, PiHome's twin.
    ../../../modules/nixos/home-dns
    ./monitoring

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

    ./services/cal-diy.nix
    ./services/concierge-server.nix
    ./services/immich.nix
    ./services/infisical.nix
    ./services/media-audio-fix
    ./services/n8n.nix
    ./services/nocodb.nix
    ./services/paperless.nix
    ./services/sotf-server.nix
    ./services/syncthing.nix
    ./services/vaultwarden.nix
  ];
}
