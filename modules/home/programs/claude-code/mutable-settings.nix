# Keeps ~/.claude/settings.json a real, writable file instead of a read-only
# nix-store symlink, so `/model`, `/plugin`, `/permissions`, `/hooks` and
# `/statusline` can persist their changes.
#
# programs.claude-code.settings (plus whatever other modules add to it, such as
# token-station's statusLine) is still the declared baseline. Home Manager
# still renders that JSON; this module only turns off the symlink and, on each
# activation, deep-merges the baseline into the live file:
#   - objects merge key by key,
#   - scalars from nix win,
#   - arrays are unioned, so CLI-added permissions and hooks survive.
# Dropping an array entry from nix does not remove it from the live file; delete
# it there by hand.
{
  config,
  lib,
  pkgs,
  ...
}: let
  settingsPath = "${config.programs.claude-code.configDir}/settings.json";
  baseline = config.home.file.${settingsPath}.source;
  jq = lib.getExe pkgs.jq;

  mergeFilter = ''
    def merge(a; b):
      if (a | type) == "object" and (b | type) == "object" then
        reduce (b | keys_unsorted[]) as $k (a; .[$k] = merge(a[$k]; b[$k]))
      elif (a | type) == "array" and (b | type) == "array" then
        reduce b[] as $x (a; if any(.[]; . == $x) then . else . + [$x] end)
      elif b == null then a
      else b
      end;
    merge($current[0]; $baseline[0])
  '';
in {
  home.file.${settingsPath}.enable = lib.mkForce false;

  home.activation.claudeCodeMutableSettings = lib.hm.dag.entryAfter ["linkGeneration"] ''
    target=${lib.escapeShellArg settingsPath}
    baseline=${lib.escapeShellArg baseline}
    tmp="$target.hm-tmp"

    run mkdir -p "$(dirname "$target")"

    if [[ -e "$target" ]] && ! ${jq} empty "$target" >/dev/null 2>&1; then
      warnEcho "claude-code: $target is not valid JSON, moving it to $target.hm-backup"
      run mv -f "$target" "$target.hm-backup"
    fi

    if [[ -e "$target" ]]; then
      if ! ${jq} -n \
        --slurpfile current "$target" \
        --slurpfile baseline "$baseline" \
        ${lib.escapeShellArg mergeFilter} >"$tmp"; then
        errorEcho "claude-code: failed to merge the nix baseline into $target"
        rm -f "$tmp"
        exit 1
      fi
    else
      ${jq} . "$baseline" >"$tmp"
    fi

    # `mv` replaces a leftover store symlink with the real file.
    chmod 644 "$tmp"
    run mv -f "$tmp" "$target"
    rm -f "$tmp"
  '';
}
