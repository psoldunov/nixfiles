{
  config,
  libs,
  pkgs,
  ...
}: {
  programs.ncmpcpp = {
    enable = true;
    mpdMusicDir = "/mnt/Media/Music";
    settings = {
      autocenter_mode = "yes";
      ignore_leading_the = "yes";
      ignore_diacritics = "yes";
      default_place_to_search_in = "database";

      ## Display Modes ##
      playlist_editor_display_mode = "columns";
      search_engine_display_mode = "columns";
      browser_display_mode = "columns";
      playlist_display_mode = "columns";

      ## General Colors ##
      colors_enabled = "yes";
      main_window_color = "white";
      header_window_color = "cyan";
      volume_color = "green";
      statusbar_color = "white";
      progressbar_color = "cyan";
      progressbar_elapsed_color = "white";

      ## Song List ##
      song_columns_list_format = "(10)[blue]{l} (30)[green]{t} (30)[magenta]{a} (30)[yellow]{b}";
      song_list_format = "{$7%a - $9}{$5%t$9}|{$5%f$9}$R{$6%b $9}{$3%l$9}";

      ## Current Item ##
      current_item_prefix = "$(cyan)$r";
      current_item_suffix = "$/r$(end)";
      current_item_inactive_column_prefix = "$(blue)$r";

      ## Alternative Interface ##
      user_interface = "alternative";
      alternative_header_first_line_format = "$0$aqqu$/a {$6%a$9 - }{$3%t$9}|{$3%f$9} $0$atqq$/a$9";
      alternative_header_second_line_format = "{{$4%b$9}{ [$8%y$9]}}|{$4%D$9}";

      ## Classic Interface ##
      song_status_format = " $6%a $7⟫⟫ $3%t $7⟫⟫ $4%b ";

      ## Visualizer ##
      #visualizer_type = "spectrum";
      #visualizer_in_stereo = "yes";
      #visualizer_look = "◆▋";

      startup_screen = "playlist";
      #startup_screen = "visualizer";
      #startup_slave_screen = "playlist";
      #startup_slave_screen_focus = "yes";
      #locked_screen_width_part = 30;

      ## Navigation ##
      cyclic_scrolling = "yes";
      header_text_scrolling = "yes";
      jump_to_now_playing_song_at_start = "yes";
      lines_scrolled = "2";

      ## Other ##
      system_encoding = "utf-8";
      regular_expressions = "extended";

      ## Selected tracks ##
      selected_item_prefix = "* ";
      discard_colors_if_item_is_selected = "yes";

      ## Seeking ##
      incremental_seeking = "yes";
      seek_time = "1";

      ## Visibility ##
      header_visibility = "yes";
      statusbar_visibility = "yes";
      titles_visibility = "yes";

      ## Progress Bar ##
      progressbar_look = "=>-";

      ## Now Playing ##
      now_playing_prefix = "> ";
      centered_cursor = "yes";

      # Misc
      display_bitrate = "yes";
      enable_window_title = "yes";
      empty_tag_marker = "";

      mpd_crossfade_time = 3;
    };
  };
}
