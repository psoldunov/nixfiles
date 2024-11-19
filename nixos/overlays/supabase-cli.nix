self: super: {
  supabase-cli = super.supabase-cli.overrideAttrs (oldAttrs: rec {
    version = "1.223.10";
    vendorHash = "sha256-0yIM1U8ugA0FutN8/gclJIubD/+fVYQbIqJzKQXXsTA=";

    src = super.fetchFromGitHub {
      owner = "supabase";
      repo = "cli";
      rev = "v${version}";
      hash = "sha256-78ocFXDui6843FP4msY/UtiDGlHxd4fr3mTHkUsPOF4=";
    };

    ldflags = [
      "-s"
      "-w"
      "-X=github.com/supabase/cli/internal/utils.Version=${version}"
    ];
  });
}
