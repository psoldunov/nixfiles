self: super: {
  prisma-engines = super.prisma-engines.overrideAttrs (oldAttrs: rec {
    pname = "prisma-engines";
    version = "6.6.0";

    src = super.fetchFromGitHub {
      owner = "prisma";
      repo = "prisma-engines";
      rev = version;
      hash = "sha256-moonBNNGWECGPvhyyeHKKAQRXj5lNP0k99JB+1POMUE=";
    };

    useFetchCargoVendor = true;
    cargoHash = "sha256-GLOGivOH8psE5/M5kYakh9Cab4Xe5Q8isY1c6YDyAB8=";
  });
}
