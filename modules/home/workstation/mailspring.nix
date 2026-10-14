# Mailspring's built-in MCP server (Preferences > MCP), which gives Claude
# Code access to mail and calendar while Mailspring runs. The app itself is
# installed by hosts/whopper/modules/desktop-environment.nix on Whopper and
# by the `mailspring` cask on the Macs (modules/darwin/homebrew.nix).
#
# Mailspring generates the bearer token and keeps it in its own config, so
# the shells read it from there at startup instead of from sops. A token
# regenerated in Mailspring reaches new shells without a rebuild. Port 2587
# is Mailspring's default; change the URL below if it is changed in the app.
{
  config,
  lib,
  pkgs,
  ...
}: let
  jq = lib.getExe pkgs.jq;
  mailspringConfig = lib.escapeShellArg (
    if pkgs.stdenv.hostPlatform.isDarwin
    then "${config.home.homeDirectory}/Library/Application Support/Mailspring/config.json"
    else "${config.xdg.configHome}/Mailspring/config.json"
  );
  tokenQuery = ''."*".core.mcp.token // empty'';
  posixExport = ''
    if [ -r ${mailspringConfig} ]; then
      MAILSPRING_MCP_TOKEN="$(${jq} -r '${tokenQuery}' ${mailspringConfig})"
      export MAILSPRING_MCP_TOKEN
    fi
  '';
in {
  programs.fish.shellInitLast = lib.mkAfter ''
    if test -r ${mailspringConfig}
      set -gx MAILSPRING_MCP_TOKEN (${jq} -r '${tokenQuery}' ${mailspringConfig})
    end
  '';
  programs.bash.bashrcExtra = lib.mkAfter posixExport;
  # zsh is only enabled on macOS (../shell/shell.nix).
  programs.zsh.initContent = lib.mkAfter posixExport;

  # The `:-` default keeps Claude Code's config valid when Mailspring has not
  # created a token yet; the server then answers 401 until it has one.
  programs.mcp.servers.mailspring = {
    url = "http://127.0.0.1:2587/mcp";
    headers.Authorization = "Bearer \${MAILSPRING_MCP_TOKEN:-}";
  };
}
