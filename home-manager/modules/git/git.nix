{
  config,
  libs,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = "Philipp Soldunov";
    userEmail = "69530789+psoldunov@users.noreply.github.com";
    ignores = [
      # Compiled source #
      ###################
      "*.com"
      "*.class"
      "*.dll"
      "*.exe"
      "*.o"
      "*.so"

      # Packages #
      ############
      # it's better to unpack these files and commit the raw source
      # git has its own built in compression methods
      "*.7z"
      "*.dmg"
      "*.gz"
      "*.iso"
      "*.jar"
      "*.rar"
      "*.tar"
      "*.zip"

      # Logs and databases #
      ######################
      "*.log"
      "*.sql"
      "*.sqlite"

      # OS generated files #
      ######################
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
    # extensions = with pkgs; [
    #   gh-copilot
    # ];
    settings.editor = "code";
    gitCredentialHelper = {
      enable = true;
      hosts = ["https://github.com" "https://gist.github.com"];
    };
  };
}
