{
  pkgs,
  config,
  ...
}: {
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
    if pgrep -x "wf-recorder" > /dev/null
    then
        echo "wf-recorder is running. Stopping it now..."
        pkill -2 wf-recorder
        ${pkgs.libnotify}/bin/notify-send "Recording stopped"
        exit 0
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
    ${pkgs.wf-recorder}/bin/wf-recorder -g "$(${pkgs.slurp}/bin/slurp)" --audio="$active_output.monitor" -f ~/Videos/Capture/screencapture-$(date +"%Y-%m-%d-%H%M%S").mp4 -c hevc_vaapi -d /dev/dri/renderD128 & disown
    exit 0
  '';

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

  create_screenshot = pkgs.writeShellScriptBin "create_screenshot" ''
    SCREENSHOTS_DIR="$(xdg-user-dir PICTURES)/Screenshots"
    if [ ! -d "$SCREENSHOTS_DIR" ]; then
      mkdir -p "$SCREENSHOTS_DIR"
      echo "Directory '$SCREENSHOTS_DIR' created."
    else
      echo "Directory '$SCREENSHOTS_DIR' already exists."
    fi
    ${pkgs.grim}/bin/grim -l 0 "$(xdg-user-dir PICTURES)/Screenshots/$(date +'screenshot_%Y-%m-%d-%H%M%S.png')"
    ${pkgs.libnotify}/bin/notify-send "Screenshot taken"
  '';

  create_screenshot_area = pkgs.writeShellScriptBin "create_screenshot_area" ''
    SCREENSHOTS_DIR="$(xdg-user-dir PICTURES)/Screenshots"
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
    ${pkgs.slurp}/bin/slurp | ${pkgs.grim}/bin/grim -l 0 -g - "$SCREENSHOTS_DIR/$(date +'screenshot_%Y-%m-%d-%H%M%S.png')"
    if [ $? -eq 0 ]
    then
        ${pkgs.libnotify}/bin/notify-send "Screenshot taken"
    fi
  '';

  kill_gamescope = pkgs.writeShellScriptBin "kill_gamescope" ''
    pkill -9 wine steam wineserver winedevice.exe explorer.exe gamescope plugplay.exe services.exe svchost.exe rpcss.exe .exe
  '';

  start_static_wallpaper = (
    pkgs.writeShellScriptBin "start_static_wallpaper" ''
      STATIC_WALLPAPER=$1
      if pgrep -x "swww-daemon" > /dev/null
      then
          echo "swww is running. Stopping it now..."
          ${pkgs.swww}/bin/swww kill
      fi
      ${pkgs.swww}/bin/swww-daemon &
      ${pkgs.swww}/bin/swww img "$STATIC_WALLPAPER"
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

  convert_all_to_woff2 = (
    pkgs.writeShellScriptBin "convert_all_to_woff2" ''
      for font in *.{otf,ttf,woff,eot}; do
          if [ -e "$font" ]; then # Skip if no files are found
              ${pkgs.woff2}/bin/woff2_compress "$font" && rm "$font"
          fi
      done
    ''
  );

  activate_expressvpn = (
    pkgs.writeScriptBin "activate_expressvpn" ''
      #!${pkgs.expect}/bin/expect -f

      set activation_code "EQPSYUFGRFHTNC5SRQTPOGO"
      spawn ${pkgs.expressvpn}/bin/expressvpn activate
      expect "Enter activation code: "
      send "$activation_code\r"
      expect "Would you like to share anonymous analytics to help us improve our service? \[Y/n\]"
      send "n\r"
      expect eof
    ''
  );
}
