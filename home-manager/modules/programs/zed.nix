{
  config,
  pkgs,
  ...
}: {
  catppuccin.zed.enable = true;

  programs.zed-editor = {
    enable = true;
    package = pkgs.zed-editor-fhs;
    installRemoteServer = true;
  };
}
