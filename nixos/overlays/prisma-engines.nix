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

    # Use system openssl.
    OPENSSL_NO_VENDOR = 1;

    nativeBuildInputs = [super.pkg-config];

    buildInputs = [super.openssl];

    preBuild = ''
      export OPENSSL_DIR=${super.lib.getDev openssl}
      export OPENSSL_LIB_DIR=${super.lib.getLib openssl}/lib

      export PROTOC=${protobuf}/bin/protoc
      export PROTOC_INCLUDE="${super.protobuf}/include";

      export SQLITE_MAX_VARIABLE_NUMBER=250000
      export SQLITE_MAX_EXPR_DEPTH=10000

      export GIT_HASH=0000000000000000000000000000000000000000
    '';

    cargoBuildFlags = [
      "-p"
      "query-engine"
      "-p"
      "query-engine-node-api"
      "-p"
      "schema-engine-cli"
      "-p"
      "prisma-fmt"
    ];

    postInstall = ''
      mv $out/lib/libquery_engine${stdenv.hostPlatform.extensions.sharedLibrary} $out/lib/libquery_engine.node
    '';

    # Tests are long to compile
    doCheck = false;

    meta = with super.lib; {
      description = "Collection of engines that power the core stack for Prisma";
      homepage = "https://www.prisma.io/";
      license = licenses.asl20;
      platforms = platforms.unix;
      mainProgram = "prisma";
      maintainers = with maintainers; [
        pimeys
        tomhoule
        aqrln
      ];
    };
  });
}
