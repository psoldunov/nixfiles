{pkgs, ...}: {
  time.timeZone = "Asia/Nicosia";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings = {
    warn-dirty = false;
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
    trusted-users = ["psoldunov"];
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowInsecure = true;
    allowBroken = true;
    permittedInsecurePackages = [
      "aspnetcore-runtime-wrapped-6.0.36"
      "aspnetcore-runtime-6.0.36"
      "dotnet-sdk-wrapped-6.0.428"
      "dotnet-sdk-6.0.428"
    ];
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
  ];

  system.stateVersion = "23.11";
}
