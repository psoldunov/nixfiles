self: super: {
  # sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  supabase-cli = super.supabase-cli.overrideAttrs (oldAttrs: rec {
    version = "2.1.1";
    vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

    src = super.fetchFromGitHub {
      owner = "supabase";
      repo = "cli";
      rev = "v${version}";
      hash = "sha256-jTAYdAJTaQhDKVwor1rj3ZhyAZ88ElvznFv5nncf4m8=";
    };

    ldflags = [
      "-s"
      "-w"
      "-X=github.com/supabase/cli/internal/utils.Version=${version}"
    ];
  });
}
