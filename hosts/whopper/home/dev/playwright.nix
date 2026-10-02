# Playwright on NixOS. The browsers Playwright downloads into
# ~/.cache/ms-playwright are generic Linux builds that do not run here, so
# everything points at the Nix-built set from playwright-driver instead.
#
# playwright-test ships the `playwright` CLI (test runner, codegen, show-trace)
# already wrapped with that browser set. The session variables extend it to
# project-local npm installs: @playwright/test in a project must match
# playwright-driver's version (`playwright --version`), or Playwright looks
# for a browser revision this path does not contain.
{
  config,
  lib,
  pkgs,
  ...
}: let
  playwrightMcp = lib.getExe pkgs.playwright-mcp;

  # Drives a live Google Chrome profile through the Playwright Extension
  # (chromewebstore id mmlmfjhmonkocbjadbfplnigmagldckm), which has to be
  # installed by hand in that profile. Each connection opens a connect page
  # in Chrome to approve. `--browser chrome` overrides the wrapper's chromium
  # default, which would launch Chrome with --no-sandbox if it is not running.
  #
  # The nixpkgs wrapper exports PLAYWRIGHT_MCP_ISOLATED=1 whenever
  # PLAYWRIGHT_MCP_USER_DATA_DIR is empty, and Playwright checks isolated mode
  # before --extension, so without the user data dir it launches a fresh
  # throwaway profile instead of attaching to the real one.
  chromeProfileServer = profileDir: {
    command = playwrightMcp;
    env.PLAYWRIGHT_MCP_USER_DATA_DIR = "${config.xdg.configHome}/google-chrome";
    args = [
      "--extension"
      "--browser"
      "chrome"
      "--executable-path"
      (lib.getExe config.programs.google-chrome.package)
      "--profile-dir-name"
      profileDir
    ];
  };
in {
  home.packages = [pkgs.playwright-test];

  home.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
  };

  programs.mcp.servers = {
    # Nix Chromium with a fresh in-memory profile per session.
    playwright.command = playwrightMcp;

    # Directory names come from ~/.config/google-chrome/Local State.
    playwright-swiss-cheese = chromeProfileServer "Profile 1";
    playwright-almost-always = chromeProfileServer "Profile 2";
  };
}
