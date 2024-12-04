self: super: {
  # sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  supabase-cli = super.supabase-cli.overrideAttrs (oldAttrs: rec {
    version = "2.0.0";
    vendorHash = "sha256-nBUV8oeoZc7N8FqEbx2Cjw4XsZW3JShv3/H58qk8JEo=";

    src = super.fetchFromGitHub {
      owner = "supabase";
      repo = "cli";
      rev = "v${version}";
      hash = "sha256-+5mcbI3pu9pahmUQnx8i2wctX/jF/CPTVaHJoH+Go4M=";
    };

    ldflags = [
      "-s"
      "-w"
      "-X=github.com/supabase/cli/internal/utils.Version=${version}"
    ];
  });
}
