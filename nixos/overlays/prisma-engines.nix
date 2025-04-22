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

    cargoHash = "sha256-1almbackh06am0d2kc4a089n3al91jg3ahgg9kcrg3zfrwhhzzrq";
  });
}
