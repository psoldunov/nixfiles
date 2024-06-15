{
  lib,
  config,
  pkgs,
  ...
}: {
  progrmas.neovim = {
    enable = true;
    defaultEditor = true;
    withNodeJS = true;
    withPython3 = true;
    withRuby = true;
    plugins = with pkgs.vimPlugins; [
      ollama-nvim
    ];
  };
}
