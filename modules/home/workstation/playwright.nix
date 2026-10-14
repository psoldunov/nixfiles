# Playwright for Claude Code: a headless MCP server with Nix's browsers, plus
# one server per Google Chrome profile that drives the live browser.
#
# On NixOS the browsers Playwright downloads into ~/.cache/ms-playwright are
# generic Linux builds that do not run, so everything points at the
# Nix-built set from playwright-driver instead. playwright-test ships the
# `playwright` CLI (test runner, codegen, show-trace) already wrapped with
# that browser set. The session variables extend it to project-local npm
# installs: @playwright/test in a project must match playwright-driver's
# version (`playwright --version`), or Playwright looks for a browser
# revision this path does not contain. macOS runs Playwright's own
# downloads, so none of that applies there.
{
  config,
  lib,
  pkgs,
  ...
}: let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  playwrightMcp = lib.getExe pkgs.playwright-mcp;

  # Directory names come from Chrome's `Local State` (profile.info_cache).
  # BigMac has no Swiss Cheese profile yet; one added there is created as
  # "Profile 2".
  chrome =
    if isDarwin
    then {
      userDataDir = "${config.home.homeDirectory}/Library/Application Support/Google/Chrome";
      # The google-chrome cask.
      executable = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
      profiles = {
        swiss-cheese = "Profile 2";
        almost-always = "Profile 1";
      };
    }
    else {
      userDataDir = "${config.xdg.configHome}/google-chrome";
      executable = lib.getExe config.programs.google-chrome.package;
      profiles = {
        swiss-cheese = "Profile 1";
        almost-always = "Profile 2";
      };
    };

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
  chromeProfileServer = name: {
    command = playwrightMcp;
    env.PLAYWRIGHT_MCP_USER_DATA_DIR = chrome.userDataDir;
    args = [
      "--extension"
      "--browser"
      "chrome"
      "--executable-path"
      chrome.executable
      "--profile-dir-name"
      chrome.profiles.${name}
    ];
  };

  # The extension shows a per-profile token that skips the connect page.
  # It lives in sops and this wrapper reads it at launch, so the value
  # never reaches /nix/store or the generated MCP config. Without a
  # readable token the server still starts and falls back to the page.
  # The tokens belong to one Chrome install, so only Whopper's are in sops
  # (secrets/whopper.yaml); BigMac uses the connect page.
  withExtensionToken = name: secret: let
    tokenFile = lib.escapeShellArg config.sops.secrets.${secret}.path;
  in
    lib.optionalAttrs (!isDarwin) {
      command = toString (pkgs.writeShellScript "playwright-mcp-${name}" ''
        if [ -r ${tokenFile} ]; then
          PLAYWRIGHT_MCP_EXTENSION_TOKEN="$(<${tokenFile})"
          export PLAYWRIGHT_MCP_EXTENSION_TOKEN
        else
          echo "playwright-mcp-${name}: ${tokenFile} unreadable, using the connect page" >&2
        fi
        exec ${playwrightMcp} "$@"
      '');
    };
in
  lib.mkMerge [
    {
      programs.mcp.servers = {
        # Nix Chromium with a fresh in-memory profile per session, headless so
        # it never opens a window. playwright-mcp runs headed by default.
        playwright = {
          command = playwrightMcp;
          args = ["--headless"];
        };

        playwright-swiss-cheese =
          chromeProfileServer "swiss-cheese"
          // withExtensionToken "swiss-cheese" "PLAYWRIGHT_SWISS_CHEESE_EXTENSION_TOKEN";
        playwright-almost-always =
          chromeProfileServer "almost-always"
          // withExtensionToken "almost-always" "PLAYWRIGHT_ALMOST_ALWAYS_EXTENSION_TOKEN";
      };
    }

    (lib.mkIf (!isDarwin) {
      sops.secrets.PLAYWRIGHT_SWISS_CHEESE_EXTENSION_TOKEN = {};
      sops.secrets.PLAYWRIGHT_ALMOST_ALWAYS_EXTENSION_TOKEN = {};

      home.packages = [pkgs.playwright-test];

      home.sessionVariables = {
        PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
        PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
      };
    })
  ]
