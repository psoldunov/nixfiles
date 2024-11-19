#! /usr/bash

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
        active_output=$(pactl info | grep 'Default Source' | awk '{print $3}')
            ;;
        "System audio")
            active_output=$(pactl info | grep 'Default Sink' | awk '{print $3}')
            ;;
        *)
            echo "Invalid choice or no selection made. Exiting..."
            exit 1
            ;;
    esac
    wf-recorder -g "$(slurp)" --audio="$active_output.monitor" -f ~/Videos/Capture/screencapture-$(date +"%Y-%m-%d-%H%M%S").mp4 -c hevc_vaapi -d /dev/dri/renderD128 & disown
    exit 0