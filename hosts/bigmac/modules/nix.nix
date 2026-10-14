# Nix itself on BigMac: upstream Nix, owned by nix-darwin (`nix.enable`), so
# nix.conf is declared here the same way modules/nixos/nix.nix and
# hosts/whopper/modules/nix.nix declare it on NixOS.
{
  config,
  inputs,
  ...
}: {
  nix = {
    enable = true;

    settings = {
      warn-dirty = false;
      experimental-features = ["nix-command" "flakes"];
      # `rebuild_system` copies the flake and its inputs here over ssh-ng
      # from the other hosts, which needs a trusted user.
      trusted-users = ["root" "psoldunov"];
      nix-path = ["nixpkgs=${inputs.nixpkgs}"];
    };

    # nix-darwin refuses auto-optimise-store, which is known to corrupt the
    # store on macOS; a scheduled optimise pass does the same job.
    optimise.automatic = true;

    # GitHub token for the private flake inputs, the same secret Whopper
    # includes (see hosts/whopper/modules/nix.nix). `!include` skips a missing
    # file, so evaluation works before sops-nix has decrypted it.
    extraOptions = ''
      !include ${config.sops.secrets.NIX_ACCESS_TOKENS.path}
    '';
  };

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };
}
