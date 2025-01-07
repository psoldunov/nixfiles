self: super: {
  # sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  supabase-cli = super.supabase-cli.overrideAttrs (oldAttrs: rec {
    version = "2.2.1";
    vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

    src = super.fetchFromGitHub {
      owner = "supabase";
      repo = "cli";
      rev = "v${version}";
      hash = "sha256-m7v31fG3ASbOFGv+IsV5IwnKyr+31i4yAAVpawvFHpo=";
    };

    ldflags = [
      "-s"
      "-w"
      "-X=github.com/supabase/cli/internal/utils.Version=${version}"
    ];
  });
}
