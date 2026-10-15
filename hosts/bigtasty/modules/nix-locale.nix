# Locale, nix settings, nix-ld, and stateVersion live in modules/nixos.
# Only BigTasty-specific insecure-package allowlist remains here.
{...}: {
  nixpkgs.config.permittedInsecurePackages = [
    "aspnetcore-runtime-wrapped-6.0.36"
    "aspnetcore-runtime-6.0.36"
    "dotnet-sdk-wrapped-6.0.428"
    "dotnet-sdk-6.0.428"
    # EOL, but the only Quick Sync runtime for the P630 (Gen 9.5): oneVPL's
    # vpl-gpu-rt starts at Gen 12. See hardware.nix.
    "intel-media-sdk-23.2.2"
  ];
}
