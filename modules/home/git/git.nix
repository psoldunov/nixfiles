{...}: {
  programs.git = {
    enable = true;
    lfs.enable = true;
    signing.format = null;
    settings.user = {
      name = "Philipp Soldunov";
      email = "69530789+psoldunov@users.noreply.github.com";
    };
    ignores = [
      "*.com"
      "*.class"
      "*.dll"
      "*.exe"
      "*.o"
      "*.so"

      "*.7z"
      "*.dmg"
      "*.gz"
      "*.iso"
      "*.jar"
      "*.rar"
      "*.tar"
      "*.zip"

      "*.log"
      "*.sql"
      "*.sqlite"

      ".DS_Store"
      ".DS_Store?"
      "._*"
      ".Spotlight-V100"
      ".Trashes"
      "ehthumbs.db"
      "Thumbs.db"
    ];
  };

  programs.gh = {
    enable = true;
    settings.editor = "code";
    gitCredentialHelper = {
      enable = true;
      hosts = ["https://github.com" "https://gist.github.com"];
    };
  };
}
