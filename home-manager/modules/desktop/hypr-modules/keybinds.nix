{
  config,
  pkgs,
  pkgs-stable,
  ...
}: let
  scripts =
    import ../../../scripts
    {
      pkgs = pkgs;
      config = config;
    };

  projects =
    import ../../../projects
    {
      config = config;
    };

  projectStrings = map (project: ''["${project.name}"]="${project.path}"'') projects.items;

  projectsString = builtins.concatStringsSep "\n" projectStrings;

  rofiProjects = pkgs.writeShellScript "rofi-project-manager" ''
    declare -A projects
    projects=(
        ${projectsString}
    )

    project_names=$(printf "%s\n" "''${!projects[@]}")

    echo $project_names

    selected_project=$(echo -e "$project_names" | rofi -no-fixed-num-lines -dmenu -p "Select a project")

    if [[ -n "$selected_project" && -n "''${projects[$selected_project]}" ]]; then
        ${pkgs.vscode}/bin/code -n "''${projects[$selected_project]}"
    else
        echo "No valid project selected."
    fi
  '';
in {
  "$MOD1" = "CTRL_SUPER";
  "$MOD2" = "CTRL_SUPER_SHIFT";
  "$MOD3" = "CTRL_ALT";
  "$MOD4" = "CTRL_ALT_SHIFT";
  "$altShift" = "ALT_SHIFT";
  bind = [
    # MOD1 Hyprland navigation VIM style
    "$MOD1, H, movefocus, l"
    "$MOD1, L, movefocus, r"
    "$MOD1, K, movefocus, u"
    "$MOD1, J, movefocus, d"

    # MOD1 Terminal + Rofi
    "$MOD1, RETURN, exec, ${pkgs.kitty}/bin/kitty"
    "$MOD1, SPACE, exec, pkill rofi || rofi -show drun"

    # MOD2 Hyprland move windows VIM style
    "$MOD2, H, movewindow, l"
    "$MOD2, L, movewindow, r"
    "$MOD2, K, movewindow, u"
    "$MOD2, J, movewindow, d"

    # MOD2 Media keys
    "$MOD2, M, exec, pamixer --toggle-mute"
    "$MOD2, P, exec, playerctl play-pause"
    "$MOD2, code:60, exec, playerctl next"
    "$MOD2, code:59, exec, playerctl previous"

    # MOD3 Workspace navigation
    "$MOD3, 1, workspace, 1"
    "$MOD3, 2, workspace, 2"
    "$MOD3, 3, workspace, 3"
    "$MOD3, 4, workspace, 4"
    "$MOD3, 5, workspace, 5"
    "$MOD3, 6, workspace, 6"
    "$MOD3, 7, workspace, 7"
    "$MOD3, 8, workspace, 8"
    "$MOD3, 9, workspace, 9"
    "$MOD3, 0, workspace, 10"

    # MOD3 Applications Launcher
    "$MOD3, F, exec, brave"
    "$MOD3, E, exec, nemo"
    "$MOD3, T, exec, ${pkgs.kitty}/bin/kitty -e tmux"
    "$MOD3, V, exec, code --new-window"
    "$MOD3, C, exec, google-chrome"
    "$MOD3, S, exec, slack"
    "$MOD3, M, exec, spotify --ozone-platform=x11"
    "$MOD3, B, exec, thunderbird"
    "$MOD3, D, exec, discord"
    "$MOD3, P, exec, 1password"
    "$MOD3, G, exec, steam"
    "$MOD3, L, exec, ags -q && ags"

    # MOD4 Move active window to a workspace
    "$MOD4, 1, movetoworkspace, 1"
    "$MOD4, 2, movetoworkspace, 2"
    "$MOD4, 3, movetoworkspace, 3"
    "$MOD4, 4, movetoworkspace, 4"
    "$MOD4, 5, movetoworkspace, 5"
    "$MOD4, 6, movetoworkspace, 6"
    "$MOD4, 7, movetoworkspace, 7"
    "$MOD4, 8, movetoworkspace, 8"
    "$MOD4, 9, movetoworkspace, 9"
    "$MOD4, 0, movetoworkspace, 10"

    # MOD4 Hyprland functions
    "$MOD4, P, togglefloating"
    "$MOD4, P, pin"
    "$MOD4, F, fullscreen"
    "$MOD4, B, togglefloating"
    # "$MOD4, V, exec, ${pkgs.cliphist}/bin/cliphist list | rofi -dmenu | ${pkgs.cliphist}/bin/cliphist decode | wl-copy"
    "$MOD4, J, togglesplit"
    "$MOD4, U, pseudo"
    "$MOD4, Z, exec, fish -c 'resetDE'"
    "$MOD4, X, exec, hyprprop | wl-copy"
    "$MOD4, M, exec, hyprpicker -a"
    "$MOD4, S, exec, create_screenshot"
    "$MOD4, A, exec, create_screenshot_area"
    "$MOD4, R, exec, record_screen"
    "$MOD4, C, exec, grab_screen_text"
    "$MOD4, K, exec, fish -c 'wkill'"

    # Nuphy binds
    "SUPER, J, workspace, e-1"
    "SUPER, K, workspace, e+1"

    # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
    "SUPER, RETURN, exec, ${pkgs.kitty}/bin/kitty"
    "CTRL, Q, killactive,"
    "SUPER, Q, killactive,"
    "CTRL SUPER, Q, exec, lock_screen"
    "SUPER, M, exit, "
    "SUPER, E, exec, nemo"
    "SUPER, A, togglespecialworkspace, music"
    "SUPER SHIFT, A, movetoworkspace, special"
    "SUPER, V, exec, ${pkgs.cliphist}/bin/cliphist list | rofi -dmenu | ${pkgs.cliphist}/bin/cliphist decode | wl-copy"
    "SUPER, D, togglefloating, "
    "SUPER SHIFT, D, togglefloating,"
    "SUPER SHIFT, D, pin,"
    "SUPER, K, pin,"
    "SUPER, SPACE, exec, pkill rofi || rofi -show drun"
    "SUPER, F, fullscreen,"
    "SUPER SHIFT, P, exec, hyprpicker | wl-copy"
    "SUPER, P, pseudo, # dwindle"
    "SUPER, J, togglesplit, # dwindle"
    "SUPER SHIFT, r, exec, fish -c 'resetDE'"
    "SUPER, code:51, exec, 1password --quick-access & disown"
    "CTRL SHIFT, 2, exec, ${scripts.grab_screen_text}/bin/grab_screen_text"
    "CTRL SHIFT, 3, exec, ${scripts.create_screenshot}/bin/create_screenshot"
    "CTRL SHIFT, 4, exec, ${scripts.create_screenshot_area}/bin/create_screenshot_area"
    "CTRL SHIFT, 5, exec, ${scripts.record_screen}/bin/record_screen"
    "CTRL SHIFT, M, exec, hyprpicker -a"

    # Move focus with mainMod + arrow keys
    "SUPER, left, movefocus, l"
    "SUPER, right, movefocus, r"
    "SUPER, up, movefocus, u"
    "SUPER, down, movefocus, d"

    # Switch workspaces with mainMod + [0-9]
    "SUPER, 1, workspace, 1"
    "SUPER, 2, workspace, 2"
    "SUPER, 3, workspace, 3"
    "SUPER, 4, workspace, 4"
    "SUPER, 5, workspace, 5"
    "SUPER, 6, workspace, 6"
    "SUPER, 7, workspace, 7"
    "SUPER, 8, workspace, 8"
    "SUPER, 9, workspace, 9"
    "SUPER, 0, workspace, 10"

    # Move active window to a workspace with mainMod + SHIFT + [0-9]
    "SUPER SHIFT, 1, movetoworkspace, 1"
    "SUPER SHIFT, 2, movetoworkspace, 2"
    "SUPER SHIFT, 3, movetoworkspace, 3"
    "SUPER SHIFT, 4, movetoworkspace, 4"
    "SUPER SHIFT, 5, movetoworkspace, 5"
    "SUPER SHIFT, 6, movetoworkspace, 6"
    "SUPER SHIFT, 7, movetoworkspace, 7"
    "SUPER SHIFT, 8, movetoworkspace, 8"
    "SUPER SHIFT, 9, movetoworkspace, 9"
    "SUPER SHIFT, 0, movetoworkspace, 10"

    # Scroll through existing workspaces with mainMod + scroll
    "SUPER, mouse_down, workspace, e+1"
    "SUPER, mouse_up, workspace, e-1"

    # media keys
    ",XF86MonBrightnessUp, exec, ddcutil -d 1 setvcp 10 + 10"
    ",XF86MonBrightnessDown, exec, ddcutil -d 1 setvcp 10 - 10"

    # # temp binds for ags
    # "SUPER, q, exec, ags -q && ags"
    # "SUPER, w, exec, ags -i"

    # Custom scripts
    "SUPER, O, exec, ${rofiProjects}"
  ];

  # Move/resize windows with mainMod + LMB/RMB and dragging
  bindm = [
    "SUPER, mouse:272, movewindow"
    "SUPER, mouse:273, resizewindow"
    #"mouse:277, mouse:272, movewindow"
    #"mouse:277, mouse:273, resizewindow"
  ];

  bindi = [",mouse:277, exec, ydotool key 125:1"];
  bindri = [",mouse:277, exec, ydotool key 125:0"];

  bindl = [
    ",XF86AudioMute, exec, pamixer --toggle-mute"
    ",XF86AudioPlay, exec, playerctl play-pause"
    ",XF86AudioNext, exec, playerctl next"
    ",XF86AudioPrev, exec, playerctl previous"
  ];

  bindel = [
    ",XF86AudioRaiseVolume, exec, pamixer --increase 5"
    ",XF86AudioLowerVolume, exec, pamixer --decrease 5"
    # MOD2 Media keys
    "$MOD2, up, exec, pamixer --increase 5"
    "$MOD2, down, exec, pamixer --decrease 5"
  ];
}
