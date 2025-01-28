self: super: {
  bun = super.bun.overrideAttrs (oldAttrs: rec {
    version = "1.2.0";
    pname = "bun";

    src = passthru.sources.${super.stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${super.stdenvNoCC.hostPlatform.system}");

    passthru = {
      sources = {
        "x86_64-linux" = super.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
          hash = "sha256-B0fpcBILE6HaU0G3UaXwrxd4vYr9cLXEWPr/+VzppFM=";
        };
      };
    };
  });
}
