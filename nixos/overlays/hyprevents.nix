self: super: {
  hyprevents = super.stdenv.mkDerivation rec {
    pname = "hyprevents";
    version = "latest"; # This reflects that the version will always be the latest commit on the main branch

    src = super.fetchFromGitHub {
      owner = "vilari-mickopf";
      repo = "hyprevents";
      rev = "master"; # Fetches the latest commit on the main branch
      sha256 = "W+wMBqNi7UfxFm5Dxl/wHXA36K9dVL5ocqllfyFWOM8="; # Placeholder, update after first build attempt
    };

    propagatedBuildInputs = with super; [
      hyprland # Assuming this is available in your Nixpkgs
      socat
    ];

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/share/${pname}
      make install PREFIX=$out
    '';

    meta = {
      description = "Invoke shell functions in response to Hyprland socket2 events";
      homepage = "https://github.com/vilari-mickopf/hyprevents";
    };
  };
}
