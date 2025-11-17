{
  pkgs,
  config,
  ...
}: {
  shadd = pkgs.writeShellScriptBin "shadd" ''
    ${pkgs.bun}/bin/bunx shadcn@latest add $1
  '';

  convert_all_to_mkv = pkgs.writeShellScriptBin "convert_all_to_mkv" ''
    # Use the current working directory
    DIRECTORY=$(pwd)

    # Loop over all mp4 files in the directory
    for file in "$DIRECTORY"/*.mp4; do
      # Extract the filename without extension
      filename=$(basename -- "$file" .mp4)

      # Convert the file using Quick Sync
      ffmpeg -vaapi_device /dev/dri/renderD128 -i "$file" -vf 'format=nv12,hwupload' -c:v h264_vaapi -qp 18 -c:a copy "$DIRECTORY/$filename.mkv"

      # Check if the conversion was successful before deleting the original file
      if [ $? -eq 0 ]; then
        echo "Converted $file to $DIRECTORY/$filename.mkv successfully."

        # Delete the original file
        rm "$file"
      else
        echo "Failed to convert $file. Skipping deletion."
      fi
    done
  '';

  restart_ags = pkgs.writeShellScriptBin "restart_ags" ''
    ${config.programs.ags.finalPackage}/bin/ags -q && ${config.programs.ags.finalPackage}/bin/ags & disown
  '';

  idle_check = pkgs.writeShellScriptBin "idle_check" ''
    player_status=$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null)
    if [ "$player_status" = "Playing" ]; then
        exit 0
    fi
    exit 1
  '';

  record_screen = pkgs.writeShellScriptBin "record_screen" ''
    source ${config.sops.secrets.SHELL_SECRETS.path}

    VIDEOS_DIR="$(xdg-user-dir VIDEOS)/Capture"
    VIDEO_FILE=$VIDEOS_DIR/screencapture-$(date +"%Y-%m-%d-%H%M%S").mp4

    if pgrep -x "wf-recorder" > /dev/null
    then
        echo "wf-recorder is running. Stopping it now..."
        pkill -2 wf-recorder
        ${pkgs.libnotify}/bin/notify-send "Recording stopped"

        TMP_VIDEO_PATH=$(${pkgs.coreutils-full}/bin/cat /tmp/wf-recorder-file)

        echo "$TMP_VIDEO_PATH"

        ${pkgs.curl}/bin/curl -H "Content-Type: multipart/form-data" -H "authorization: $ZIPLINE_TOKEN" -F file=@$TMP_VIDEO_PATH https://zipline.theswisscheese.com/api/upload | ${pkgs.jq}/bin/jq -r '.files[0]' | ${pkgs.wl-clipboard}/bin/wl-copy

        rm /tmp/wf-recorder-file

        exit 0
    fi

    if [ ! -d "$VIDEOS_DIR" ]; then
      mkdir -p "$VIDEOS_DIR"
      echo "Directory '$VIDEOS_DIR' created."
    else
      echo "Directory '$VIDEOS_DIR' already exists."
    fi

    CHOICE=$(echo -e "Microphone audio\nSystem audio" | rofi -location 2 -yoffset 30 -no-fixed-num-lines -dmenu -p "Select audio source")
    case $CHOICE in
      "Microphone audio")
        active_output=$(${pkgs.pulseaudio}/bin/pactl info | grep 'Default Source' | awk '{print $3}')
            ;;
        "System audio")
            active_output=$(${pkgs.pulseaudio}/bin/pactl info | grep 'Default Sink' | awk '{print $3}')
            ;;
        *)
            echo "Invalid choice or no selection made. Exiting..."
            exit 1
            ;;
    esac

    echo "$VIDEO_FILE" > /tmp/wf-recorder-file

    ${pkgs.wf-recorder}/bin/wf-recorder -g "$(${pkgs.slurp}/bin/slurp)" --audio="$active_output.monitor" -f $VIDEO_FILE & disown

    exit 0
  '';

  # -c hevc_vaapi -d /dev/dri/renderD128

  grab_screen_text = pkgs.writeShellScriptBin "grab_screen_text" ''
    if pgrep -x "slurp" > /dev/null
    then
        echo "slurp is already running"
        exit 1
    fi
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.tesseract}/bin/tesseract - - -l eng | ${pkgs.wl-clipboard}/bin/wl-copy
    # ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.tesseract}/bin/tesseract - - -l rus+eng | ${pkgs.wl-clipboard}/bin/wl-copy
    if [ $? -eq 0 ]
    then
        ${pkgs.libnotify}/bin/notify-send "Text copied to clipboard"
    fi
  '';

  sops-code = pkgs.writeShellScriptBin "sops-code" ''
    EDITOR="${pkgs.vscode}/bin/code --wait" ${pkgs.sops}/bin/sops $1
  '';

  create_screenshot = pkgs.writeShellScriptBin "create_screenshot" ''
    source ${config.sops.secrets.SHELL_SECRETS.path}

    SCREENSHOTS_DIR="$(xdg-user-dir PICTURES)/Screenshots"
    SCREENSHOT_FILE="$SCREENSHOTS_DIR/$(date +'screenshot_%Y-%m-%d-%H%M%S.png')"

    if [ ! -d "$SCREENSHOTS_DIR" ]; then
      mkdir -p "$SCREENSHOTS_DIR"
      echo "Directory '$SCREENSHOTS_DIR' created."
    else
      echo "Directory '$SCREENSHOTS_DIR' already exists."
    fi
    ${pkgs.grim}/bin/grim -l 0 "$SCREENSHOT_FILE"
    ${pkgs.libnotify}/bin/notify-send "Screenshot taken"
    ${pkgs.curl}/bin/curl -H "Content-Type: multipart/form-data" -H "authorization: $ZIPLINE_TOKEN" -F file=@$SCREENSHOT_FILE https://zipline.theswisscheese.com/api/upload
    ${pkgs.wl-clipboard}/bin/wl-copy < $SCREENSHOT_FILE
  '';

  create_screenshot_area = pkgs.writeShellScriptBin "create_screenshot_area" ''
    source ${config.sops.secrets.SHELL_SECRETS.path}

    SCREENSHOTS_DIR="$(xdg-user-dir PICTURES)/Screenshots"
    SCREENSHOT_FILE="$SCREENSHOTS_DIR/$(date +'screenshot_%Y-%m-%d-%H%M%S.png')"

    if pgrep -x "slurp" > /dev/null
    then
        echo "slurp is already running"
        exit 1
    fi
    if [ ! -d "$SCREENSHOTS_DIR" ]; then
      mkdir -p "$SCREENSHOTS_DIR"
      echo "Directory '$SCREENSHOTS_DIR' created."
    else
      echo "Directory '$SCREENSHOTS_DIR' already exists."
    fi
    ${pkgs.slurp}/bin/slurp | ${pkgs.grim}/bin/grim -l 0 -g - "$SCREENSHOT_FILE"
    if [ $? -eq 0 ]
    then
        ${pkgs.libnotify}/bin/notify-send "Screenshot taken"
        ${pkgs.curl}/bin/curl -H "Content-Type: multipart/form-data" -H "authorization: $ZIPLINE_TOKEN" -F file=@$SCREENSHOT_FILE https://zipline.theswisscheese.com/api/upload
        ${pkgs.wl-clipboard}/bin/wl-copy < $SCREENSHOT_FILE
    fi
  '';

  kill_gamescope = pkgs.writeShellScriptBin "kill_gamescope" ''
    pkill -9 wine steam wineserver winedevice.exe explorer.exe gamescope plugplay.exe services.exe svchost.exe rpcss.exe .exe
  '';

  # start_static_wallpaper = (
  #   pkgs.writeShellScriptBin "start_static_wallpaper" ''
  #     STATIC_WALLPAPER=$1
  #     if pgrep -x "swww-daemon" > /dev/null
  #     then
  #         echo "swww is running. Stopping it now..."
  #         ${pkgs.swww}/bin/swww kill
  #     fi
  #     ${pkgs.swww}/bin/swww-daemon &
  #     ${pkgs.swww}/bin/swww img "$STATIC_WALLPAPER"
  #     ${pkgs.imagemagick}/bin/magick "$STATIC_WALLPAPER" -blur 0x10 "/usr/share/backgrounds/user/lock_background.png"
  #     exit 0
  #   ''
  # );

  start_static_wallpaper = (
    pkgs.writeShellScriptBin "start_static_wallpaper" ''
      STATIC_WALLPAPER=$1
      hyprctl hyprpaper preload "$STATIC_WALLPAPER"
      hyprctl hyprpaper wallpaper "HDMI-A-1,$STATIC_WALLPAPER"
      ${pkgs.imagemagick}/bin/magick "$STATIC_WALLPAPER" -blur 0x10 "/usr/share/backgrounds/user/lock_background.png"
      exit 0
    ''
  );

  update_system = (
    pkgs.writeShellScriptBin "update_system" ''
      cd /etc/nixos
      git add .
      git commit -am "pre-update commit $(date '+%d/%m/%Y %H:%M:%S')"
      sudo nix flake update
      sudo nixos-rebuild switch --show-trace --upgrade-all
    ''
  );

  rebuild_system = (
    pkgs.writeShellScriptBin "rebuild_system" ''
      cd /etc/nixos
      git add .
      git commit -am "rebuild commit $(date '+%d/%m/%Y %H:%M:%S')"
      sudo nixos-rebuild switch --show-trace
    ''
  );

  clean_system = (
    pkgs.writeShellScriptBin "clean_system" ''
      sudo nix-collect-garbage -d
      nix-collect-garbage -d
    ''
  );

  make_timed_commit = (
    pkgs.writeShellScriptBin "make_timed_commit" ''
      git add .
      git commit -am "commit $(date '+%d/%m/%Y %H:%M:%S')"
    ''
  );

  start_video_wallpaper = (
    pkgs.writeShellScriptBin "start_video_wallpaper" ''
      if pgrep -x "swww-daemon" > /dev/null
      then
          echo "swww is running. Stopping it now..."
          ${pkgs.swww}/bin/swww kill
      fi
      VIDEO_DIR="${config.home.homeDirectory}/Videos/Wallpapers"
      if pgrep -x "mpvpaper" > /dev/null
      then
          echo "mpvpaper is running. Stopping it now..."
          pkill -x "mpvpaper"
      fi
      sleep 1
      RANDOM_VIDEO=$(find "$VIDEO_DIR" -type f \( -name "*.mp4" -o -name "*.mkv" \) | shuf -n 1)
      VIDEO_PATH=$RANDOM_VIDEO
      ${pkgs.mpvpaper}/bin/mpvpaper -o "loop no-audio" '*' "$VIDEO_PATH" &
      ${pkgs.ffmpeg-full}/bin/ffmpeg -y -i "$VIDEO_PATH" -vframes 1 "/tmp/lock_background.png"
      ${pkgs.imagemagick}/bin/magick "/tmp/lock_background.png" -blur 0x10 "/usr/share/backgrounds/user/lock_background.png"
      exit 0
    ''
  );

  convert_all_to_webp = (
    pkgs.writeShellScriptBin "convert_all_to_webp" ''
      for img in *.{jpg,jpeg,png,gif}; do
          if [ -e "$img" ]; then # Skip if no files are found
              ${pkgs.imagemagick}/bin/magick "$img" "$(echo "$img" | sed 's/\.[^.]*$//').webp" && rm "$img"
          fi
      done
    ''
  );

  fix_xdph = (
    pkgs.writeShellScriptBin "fix_xdph" ''
      ${pkgs.systemd}/bin/systemctl --user disable xdg-desktop-portal-hyprland.service &>/dev/null
      ${pkgs.systemd}/bin/systemctl --user enable xdg-desktop-portal-hyprland.service &>/dev/null
      ${pkgs.systemd}/bin/systemctl --user start xdg-desktop-portal-hyprland.service &>/dev/null
      ${pkgs.systemd}/bin/systemctl --user status xdg-desktop-portal-hyprland.service
    ''
  );

  restart_steam = (
    pkgs.writeShellScriptBin "restart_steam" ''
      pkill -9 steam && steam & disown
      exit 0
    ''
  );

  convert_all_to_woff2 = (
    pkgs.writeShellScriptBin "convert_all_to_woff2" ''
      for font in *.{otf,ttf,woff,eot}; do
          if [ -e "$font" ]; then # Skip if no files are found
              ${pkgs.woff2}/bin/woff2_compress "$font" && rm "$font"
          fi
      done
    ''
  );

  restart_xdg_desktop_portal = (
    pkgs.writeShellScriptBin "restart_xdg_desktop_portal" ''
      ${pkgs.systemd}/bin/systemctl --user disable xdg-desktop-portal-hyprland.service
      ${pkgs.systemd}/bin/systemctl --user enable xdg-desktop-portal-hyprland.service
      ${pkgs.systemd}/bin/systemctl --user restart xdg-desktop-portal-hyprland.service
    ''
  );

  # cursor_open = (
  #   pkgs.writeShellScriptBin "cursor_open" ''
  #     nohup ${pkgs.code-cursor}/bin/cursor "$@" >/dev/null 2>&1 &
  #   ''
  # );

  cycle_monitor_refresh_rate = (
    pkgs.writeShellScriptBin "cycle-rr" ''
      ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-1,3840x2160@120,auto,auto
      ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-1,3840x2160@144,auto,auto
    ''
  );

  brightness_control = (
    pkgs.writeShellScriptBin "brightness_control" ''
      # File to store timestamp and count
      TEMP_FILE="/tmp/brightness_counter"
      TIMEOUT=1  # Timeout in seconds
      STEP=10    # Each press changes brightness by 10%

      # Function to get current brightness
      get_current_brightness() {
          ddccontrol -p -r 0x10 2>/dev/null | grep -oP 'Control 0x10: \+/\K\d+(?=/\d+)'
      }

      # Function to apply brightness change
      apply_brightness() {
          local change=$1
          local current=$(get_current_brightness)
          local new_value=$((current + change))

          # Ensure brightness stays within 0-100 range
          if [ $new_value -gt 100 ]; then
              new_value=100
          elif [ $new_value -lt 0 ]; then
              new_value=0
          fi

          echo "Applying brightness change:"
          echo "Current brightness: $current"
          echo "Change amount: $change"
          echo "New brightness: $new_value"

          ddccontrol -p -r 0x10 -w $new_value >/dev/null 2>&1
      }

      # Get direction from argument
      direction=$1  # "up" or "down"

      # Check if direction is provided
      if [ -z "$direction" ]; then
          echo "Usage: $0 [up|down]"
          exit 1
      fi

      # Get current time
      current_time=$(date +%s)

      if [ -f "$TEMP_FILE" ]; then
          # Read last timestamp and count
          read last_time last_direction count < "$TEMP_FILE"

          # Check if we're within timeout and same direction
          if [ $((current_time - last_time)) -le $TIMEOUT ] && [ "$direction" = "$last_direction" ]; then
              # Increment count
              count=$((count + 1))
              echo "Keypress count: $count"
          else
              # Reset count
              count=1
              echo "Starting new count: $count"
          fi
      else
          # First press
          count=1
          last_time=$current_time
          echo "First keypress"
      fi

      # Save current state
      echo "$current_time $direction $count" > "$TEMP_FILE"

      # If this is the last press (after timeout)
      if [ $((current_time - last_time)) -gt $TIMEOUT ] || [ ! -f "$TEMP_FILE" ]; then
          # Calculate total change
          change=$((count * STEP))
          if [ "$direction" = "down" ]; then
              change=$((-change))
          fi

          # Apply the change
          apply_brightness $change
      fi
    ''
  );
}
