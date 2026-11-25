# The source folder of each skill in ./mattpocock-skills.nix. A skill with a
# ./skill-addons/<name>.md gets that file appended to its SKILL.md: the
# grilling addon routes grill-me and grill-with-docs rounds through Ensemblr's
# ask-user-question tool. settings.nix links the result for Claude Code and
# pi, ../codex/skills.nix for Codex.
{
  inputs,
  lib,
  pkgs,
}: let
  addons = ./skill-addons;
  withAddon = name: upstream:
    pkgs.runCommand "mattpocock-skill-${name}" {} ''
      cp -r ${upstream} $out
      chmod -R u+w $out
      printf '\n' >> $out/SKILL.md
      cat ${addons + "/${name}.md"} >> $out/SKILL.md
    '';
  source = name: path: let
    upstream = "${inputs.mattpocock-skills}/skills/${path}";
  in
    if builtins.pathExists (addons + "/${name}.md")
    then withAddon name upstream
    else upstream;
in
  lib.mapAttrs source (import ./mattpocock-skills.nix)
