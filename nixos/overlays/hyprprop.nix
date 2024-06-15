self: super: {
  hyprprop = super.stdenv.mkDerivation rec {
    pname = "hyprprop";
    version = "latest";  # This reflects that the version will always be the latest commit on the main branch

    src = super.fetchFromGitHub {
      owner = "vilari-mickopf";
      repo = "hyprprop";
      rev = "master";  # Fetches the latest commit on the main branch
      sha256 = "J3GM+o+kcp1rprWREJTSUbIPZheoPOu2wT43/GaO7oA="; # Placeholder, update after first build attempt
    };

    propagatedBuildInputs = with super; [
      hyprland     # Assuming this is available in your Nixpkgs
      hyprevents   # Assuming this is available either via Nixpkgs or another overlay
      socat
      slurp
      jq
    ];

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/share/${pname}
      make install PREFIX=$out
    '';

    meta = {
      description = "xprop for Hyprland";
      homepage = "https://github.com/vilari-mickopf/hyprprop";
    };
  };
}