# A Stream Deck key for Clokkr, the time tracker: on Whopper from
# hosts/whopper/home/programs/clokkr.nix, on a Mac the installed Clokkr.app.
# ./clokkr.sh draws it: the Clokkr mark in the running task's colour, the
# session's elapsed time and the task's name. Paused, it shows the task's time
# today under an orange "Paused"; stopped, today's total over all tasks. A tap
# pauses the running timer or starts the current task, and opens the popover
# when there is no task to start; holding the key opens the popover.
#
# `clokkr` provides the `clokkr` CLI and `placeholder` is the image shown
# until the first drawing. Evaluates to the key at an index.
{
  lib,
  pkgs,
  inputs,
  button,
  clokkr,
  placeholder,
}: let
  # The shapes of Clokkr's symbolic icon without the group that colours them,
  # so ./clokkr.sh can fill them in the task's colour. Read from the flake's
  # source, since its package builds for Linux only.
  mark = pkgs.runCommand "deckmaster-clokkr-mark.svg" {} ''
    sed -n '/<g /,/<\/g>/{/<g \|<\/g>/!p}' \
      ${inputs.clokkr}/packaging/icon/dev.soldunov.clokkr-symbolic.svg > $out
    if ! grep --quiet '<path' $out; then
      echo "No shapes found in Clokkr's symbolic icon." >&2
      exit 1
    fi
  '';

  script = lib.getExe (pkgs.writeShellApplication {
    name = "deckmaster-clokkr";
    runtimeInputs = [clokkr pkgs.coreutils pkgs.librsvg];
    runtimeEnv.MARK_FILE = mark;
    text = builtins.readFile ./clokkr.sh;
  });
in
  # It has no label, so the drawing fills the key.
  index:
    button index {
      label = "";
      icon = placeholder;
      iconCommand = "${script} icon";
      action.exec = "${script} toggle";
      hold.exec = "${script} open";
    }
