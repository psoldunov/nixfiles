self: super: {
  prisma-engines = super.prisma-engines.overrideAttrs (oldAttrs: rec {
    pname = "prisma-engines";
    version = "6.6.0";

    src = super.fetchFromGitHub {
      owner = "prisma";
      repo = "prisma-engines";
      rev = version;
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1=";
    };

    cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA0=";
  });
}
