# Stream Deck keys for Claude Code and Codex plan usage. ./usage.sh draws each
# key from the snapshot that Token Station (../token-station.nix) publishes on
# the session bus: the provider's logo, one usage window with its percentage,
# a bar in the level colour and the time until the window resets. A tap shows
# the provider's next window (for Claude: session, weekly, then per model), and
# holding the key makes Token Station refresh every provider at once.
{
  lib,
  pkgs,
  button,
  svgIcon,
}: let
  usage = lib.getExe (pkgs.writeShellApplication {
    name = "deckmaster-usage";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.librsvg pkgs.systemd];
    text = builtins.readFile ./usage.sh;
  });

  # Brand marks from Lobe Icons (MIT), pinned to one commit.
  lobeIcon = name: hash:
    pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/lobehub/lobe-icons/329f378cbd1a88f45b60cd096b9111ce16f3ea39/packages/static-svg/icons/${name}.svg";
      inherit hash;
    };

  logos = {
    claude = lobeIcon "claude-color" "sha256-oxAfMEehGaoRglrZNpUQ8MRyQoyMUtQg4xvGLbRKg2Q=";
    # The Codex app icon without its white tile, so the cloud sits on the
    # black key.
    codex = pkgs.runCommand "codex-logo.svg" {} ''
      sed 's|<path d="M19.503 0H4.496[^>]*></path>||' \
        ${lobeIcon "codex-color" "sha256-Si9Dzka1tuNyLJUIj4jSbvkeaowuWY5wZCocVDZzhuQ="} > $out
      if grep --quiet 'fill="#fff"' $out; then
        echo "The white tile is still in the Codex logo." >&2
        exit 1
      fi
    '';
  };

  # A logo as the data: URI that ./usage.sh puts into the key image.
  logoUri = provider:
    pkgs.runCommand "deckmaster-${provider}-logo-uri" {} ''
      printf 'data:image/svg+xml;base64,%s\n' "$(base64 --wrap=0 ${logos.${provider}})" > $out
    '';
in
  # A key for `provider`, a Token Station provider id. It has no label, so the
  # drawn image fills the key. The plain logo shows only until the first drawing.
  index: provider:
    button index {
      label = "";
      icon = svgIcon provider logos.${provider};
      iconCommand = "${usage} icon ${provider} ${logoUri provider}";
      action.exec = "${usage} next ${provider}";
      hold.exec = "${usage} refresh";
    }
