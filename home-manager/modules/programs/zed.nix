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

  home.file."${config.xdg.dataHome}/zed/extensions/work/discord-presence/discord-presence-lsp-v0.9.0/discord-presence-lsp-x86_64-unknown-linux-gnu/discord-presence-lsp" = {
    source = pkgs.writeShellScript "discord-presence-lsp" ''
      ${pkgs.zed-discord-presence}/bin/discord-presence-lsp
    '';
    executable = true;
    force = true;
  };
}
