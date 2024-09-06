{
  windowrule = [
    "fullscreen,class:(steam_app_)(.*)$"
    "noanim,class:(steam_app_)(.*)$"
    "noborder,class:(steam_app_)(.*)$"
    "noshadow,class:(steam_app_)(.*)$"
    "noblur,class:(steam_app_)(.*)$"
  ];
  windowrulev2 = [
    "rounding 4,title:^(Firefox — Sharing Indicator)$"
    "noborder,title:^(Firefox — Sharing Indicator)$"
    "move 3760 2,title:^(Firefox — Sharing Indicator)$"
    "size 76 32,title:^(Firefox — Sharing Indicator)$"
    "float,class:(xfce-polkit)"
    "noborder,class:(xfce-polkit)"
    "float,class:(polkit-gnome-authentication-agent-1)"
    "noborder,class:(polkit-gnome-authentication-agent-1)"
    "noborder,class:(steam)"
    "rounding 0,class:(steam)"
    "nomaxsize,class:(steam)"
    "float,title:^(.*Picture in picture.*)$"
    "float,title:^(.*File Operation Progress.*)$"
    "pin,title:^(.*Picture in picture.*)$"
    "rounding 0,title:^(.*Picture in picture.*)$"
    "float,title:^(Firefox — Sharing Indicator)$"
    "float,class:(pavucontrol)"
    "float,class:(com.nextcloud.desktopclient.nextcloud)"
    # "windowdance,class:(com.nextcloud.desktopclient.nextcloud)"
    "nomaxsize,class:(^.*wine.*$)"
    # "forceinput,class:(Brave-browser)"
    # "forceinput,class:(Slack)"
    "noborder,class:(Xdg-desktop-portal-gtk)"
    "noblur,class:(Xdg-desktop-portal-gtk)"
    "noshadow,class:(Xdg-desktop-portal-gtk)"
    "noanim,class:(Xdg-desktop-portal-gtk)"
    "tile,class:(thunderbird),title:^(.*\ \-\ Mozilla Thunderbird)$"
    "suppressevent maximize fullscreen,class:(thunderbird),title:^(?!.*\ \-\ Mozilla Thunderbird)$"
    "center,class:(thunderbird),title:^(?!.*\ \-\ Mozilla Thunderbird)$"
    "float,class:(thunderbird),title:^(?!.*\ \-\ Mozilla Thunderbird)$"
    "float,class:(thunderbird),title:(Edit Event: .*)$"
    "tile,class:(1Password),title:^(.*\ \-\ 1Password)$"
    "suppressevent maximize fullscreen,class:(1Password),title:^(?!.*\ \-\ 1Password)$"
    "center,class:(1Password),title:^(?!.*\ \-\ 1Password)$"
    "float,class:(1Password),title:^(?!.*\ \-\ 1Password)$"
    "pin,class:1Password,title:1Password"
    "center,class:1Password,title:1Password"
    "float,class:(python3),title:^(.*Maestral.*)$"
    "float,class:(org.onionshare.OnionShare)"
    "float,class:(solaar)"
    "float,class:polkit-gnome-authentication-agent-1"
    "pin,class:polkit-gnome-authentication-agent-1"
    "dimaround,class:polkit-gnome-authentication-agent-1"
    "pin,class:(firefox),title:(Picture-in-Picture)$"
    "rounding 0,class:(firefox),title:(Picture-in-Picture)$"
    "float,class:(firefox),title:(Picture-in-Picture)$"
    "float,class:(thunar),title:(Confirm to replace files)$"
    "opacity 0.0 override 0.0 override,class:^(xwaylandvideobridge)$"
    "noanim,class:^(xwaylandvideobridge)$"
    "nofocus,class:^(xwaylandvideobridge)$"
    "noinitialfocus,class:^(xwaylandvideobridge)$"
    "idleinhibit fullscreen,class:^(duckstation-qt)$"
    "idleinhibit always,class:^(steam_app_*)$"
    "idleinhibit fullscreen,class:^(firefox)$"
    "idleinhibit always,class:^(Ryujinx)$"
    "float,class:^()$,title:(Google Chrome)$"
    "stayfocused, title:^()$,class:^(steam)$"
    "minsize 1 1, title:^()$,class:^(steam)$"
    "float,class:^(firefox)$,title:^(.*Font Finder — Mozilla Firefox)$"
    "workspace 3,class:(thunderbird)"
    "workspace 3,class:(Slack)"
    "workspace 4,class:(ferdium)"
    "workspace special:music,class:(Spotify)"
    "workspace special:music,class:(rhythmbox)"
    "workspace special:music,class:(Plexamp)"
    "float,class:(Plexamp)"
    "workspace 5,class:(tidal-hifi)"
    "workspace 6,class:^(steam)$,title:(Steam)"
    "workspace 6,class:^(heroic)$"
    "workspace 10,class:^steam_app_.*$"
    "workspace 10,class:^(hl2_linux)$"
    "workspace 10,class:^(hl_linux)$"
    "workspace 10,class:^(steam)$,title:(Steam Big Picture Mode)"
    "workspace 10,class:^(gamescope)$"
    "float,class:^(steam)$,title:^notificationtoasts_.*$"
    "pin,class:^(steam)$,title:^notificationtoasts_.*$"
    "noborder,class:(com.flipperdevices.qFlipper)"
    "noblur,class:(com.flipperdevices.qFlipper)"
    "noshadow,class:(com.flipperdevices.qFlipper)"
    "noanim,class:(com.flipperdevices.qFlipper)"
    "float,class:(com.flipperdevices.qFlipper)"
    "float,class:(Upwork)"
    "float,class:(com-group_finity-mascot-Main)"
    "noblur,class:(com-group_finity-mascot-Main)"
    "nofocus,class:(com-group_finity-mascot-Main)"
    "noshadow,class:(com-group_finity-mascot-Main)"
    "noborder,class:(com-group_finity-mascot-Main)"
    "tile,class:(dev.warp.Warp)"
    "noborder,class:(dev.warp.Warp)"
    "noblur,class:(zoom)"
    "rounding 8,class:(zoom)"
    "float,class:(zoom),title:(as_toolbar)"
    "pin,class:(zoom),title:(as_toolbar)"
    "noborder,class:(zoom),title:(as_toolbar)"
    "noblur,class:(zoom),title:(as_toolbar)"
    "noshadow,class:(zoom),title:(as_toolbar)"
    "noanim,class:(zoom),title:(as_toolbar) "
    "minsize 816 91,class:(zoom),title:(as_toolbar)"
    "maxsize 816 91,class:(zoom),title:(as_toolbar)"
    "rounding 0,class:(zoom),title:(as_toolbar)"
    "rounding 20,class:(zoom),title:(zoom)"
    "noborder,class:(zoom),title:(zoom)"
    "float,class:(zoom),title:(zoom_linux_float_video_window)"
    "pin,class:(zoom),title:(zoom_linux_float_video_window)"
    "noborder,class:(zoom),title:(zoom_linux_float_video_window)"
    "noblur,class:(zoom),title:(zoom_linux_float_video_window)"
    "noshadow,class:(zoom),title:(zoom_linux_float_video_window)"
    "noanim,class:(zoom),title:(zoom_linux_float_video_window)"
    "rounding 0,class:(zoom),title:(zoom_linux_float_video_window)"
    "float,class:(com.nextcloud.desktopclient.nextcloud)"
    "noborder,class:(com.nextcloud.desktopclient.nextcloud)"
    "noblur,class:(com.nextcloud.desktopclient.nextcloud)"
    "noinitialfocus,class:(com.nextcloud.desktopclient.nextcloud)"
    "move onscreen cursor 50% 0%,class:(com.nextcloud.desktopclient.nextcloud)"
    "noanim,class:(com.nextcloud.desktopclient.nextcloud)"
    "noanim,class:(gamescope)"
    "noborder,class:(gamescope)"
    "noshadow,class:(gamescope)"
    "noblur,class:(gamescope)"
    # "forceinput,class:(gamescope)"
    "fullscreen,class:(gamescope)"
    "fullscreen,title:(Steam Big Picture Mode)"
    "float,class:(yad),title:^(SteamTinkerLaunch-MainMenu)$"
    "float,class:(yad),title:^(SteamTinkerLaunch-*)$"
    "float,class:(org.speedcrunch.)"
    "pin,class:(org.speedcrunch.)"
    "float,class:^(nemo)$,title:^(.*\ Properties)$"
    "maxsize 1920 1080,class:(xdg-desktop-portal-gtk)"
    "float,class:(xdg-desktop-portal-gtk)"
    "pin,class:(xdg-desktop-portal-gtk)"
    "dimaround,class:(xdg-desktop-portal-gtk)"
    "stayfocused,class:(Rofi)"
  ];
  layerrule = ["dimaround,rofi"];
}
