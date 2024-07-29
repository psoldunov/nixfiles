{config, ...}: {
  home.file."${config.xdg.configHome}/zed/themes/catppuccin-peach.json" = {
    text = ''
      {
          "$schema": "https://zed.dev/schema/themes/v0.1.0.json",
          "name": "Catppuccin",
          "author": "Andrew Tec <andrewtec@enjoi.dev>",
          "themes": [
              {
                  "name": "Catppuccin Latte (peach)",
                  "appearance": "light",
                  "style": {
                      "background.appearance": "blurred",
                      "border": "#ccd0da",
                      "border.variant": "#f47a35",
                      "border.focused": "#7287fd",
                      "border.selected": "#fe640b",
                      "border.transparent": "#40a02b",
                      "border.disabled": "#acb0be",
                      "elevated_surface.background": "#e6e9ef",
                      "surface.background": "#eff1f5",
                      "background": "#eff1f5",
                      "element.background": "#dce0e8",
                      "element.hover": "#9ca0b04d",
                      "element.active": "#fe640b33",
                      "element.selected": "#ccd0da99",
                      "element.disabled": "#9ca0b0",
                      "drop_target.background": "#fe640b66",
                      "ghost_element.background": null,
                      "ghost_element.hover": "#acb0be4d",
                      "ghost_element.active": "#acb0be80",
                      "ghost_element.selected": "#9ca0b059",
                      "ghost_element.disabled": "#9ca0b0",
                      "text": "#4c4f69",
                      "text.muted": "#5c5f77",
                      "text.placeholder": "#acb0be",
                      "text.disabled": "#9ca0b0",
                      "text.accent": "#fe640b",
                      "icon": "#4c4f69",
                      "icon.muted": "#8c8fa1",
                      "icon.disabled": "#9ca0b0",
                      "icon.placeholder": "#acb0be",
                      "icon.accent": "#fe640b",
                      "status_bar.background": "#dce0e8",
                      "title_bar.background": "#dce0e8",
                      "title_bar.inactive_background": "#dce0e8d9",
                      "toolbar.background": "#eff1f5",
                      "tab_bar.background": "#dce0e8",
                      "tab.inactive_background": "#e6e9ef",
                      "tab.active_background": "#eff1f5",
                      "search.match_background": "#17929933",
                      "panel.background": "#e6e9ef",
                      "panel.focused_border": "#4c4f69",
                      "pane.focused_border": "#4c4f69",
                      "scrollbar.thumb.background": "#fe640b33",
                      "scrollbar.thumb.hover_background": "#9ca0b0",
                      "scrollbar.thumb.border": "#acb0be80",
                      "scrollbar.track.background": "#eff1f5",
                      "scrollbar.track.border": "#4c4f6912",
                      "editor.foreground": "#4c4f69",
                      "editor.background": "#eff1f5",
                      "editor.gutter.background": "#eff1f5",
                      "editor.subheader.background": "#e6e9ef",
                      "editor.active_line.background": "#4c4f690d",
                      "editor.highlighted_line.background": null,
                      "editor.line_number": "#8c8fa1",
                      "editor.active_line_number": "#fe640b",
                      "editor.invisible": "#7c7f9366",
                      "editor.wrap_guide": "#acb0be",
                      "editor.active_wrap_guide": "#acb0be",
                      "editor.document_highlight.read_background": "#6c6f8529",
                      "editor.document_highlight.write_background": "#6c6f8529",
                      "terminal.background": "#eff1f5",
                      "terminal.foreground": "#4c4f69",
                      "terminal.dim_foreground": "#8c8fa1",
                      "terminal.bright_foreground": "#4c4f69",
                      "terminal.ansi.black": "#bcc0cc",
                      "terminal.ansi.red": "#d20f39",
                      "terminal.ansi.green": "#40a02b",
                      "terminal.ansi.yellow": "#df8e1d",
                      "terminal.ansi.blue": "#1e66f5",
                      "terminal.ansi.magenta": "#ea76cb",
                      "terminal.ansi.cyan": "#179299",
                      "terminal.ansi.white": "#4c4f69",
                      "terminal.ansi.bright_black": "#acb0be",
                      "terminal.ansi.bright_red": "#d20f39",
                      "terminal.ansi.bright_green": "#40a02b",
                      "terminal.ansi.bright_yellow": "#df8e1d",
                      "terminal.ansi.bright_blue": "#1e66f5",
                      "terminal.ansi.bright_magenta": "#ea76cb",
                      "terminal.ansi.bright_cyan": "#179299",
                      "terminal.ansi.bright_white": "#6c6f85",
                      "terminal.ansi.dim_black": "#bcc0cc",
                      "terminal.ansi.dim_red": "#d20f39",
                      "terminal.ansi.dim_green": "#40a02b",
                      "terminal.ansi.dim_yellow": "#df8e1d",
                      "terminal.ansi.dim_blue": "#1e66f5",
                      "terminal.ansi.dim_magenta": "#ea76cb",
                      "terminal.ansi.dim_cyan": "#179299",
                      "terminal.ansi.dim_white": "#5c5f77",
                      "link_text.hover": "#04a5e5",
                      "conflict": "#8839ef",
                      "conflict.border": "#8839ef",
                      "conflict.background": "#e6e9ef",
                      "created": "#40a02b",
                      "created.border": "#40a02b",
                      "created.background": "#e6e9ef",
                      "deleted": "#d20f39",
                      "deleted.border": "#d20f39",
                      "deleted.background": "#e6e9ef",
                      "error": "#d20f39",
                      "error.border": "#d20f39",
                      "error.background": "#e6e9ef",
                      "hidden": "#9ca0b0",
                      "hidden.border": "#9ca0b0",
                      "hidden.background": "#e6e9ef",
                      "hint": "#acb0be",
                      "hint.border": "#acb0be",
                      "hint.background": "#e6e9ef",
                      "ignored": "#9ca0b0",
                      "ignored.border": "#9ca0b0",
                      "ignored.background": "#e6e9ef",
                      "info": "#179299",
                      "info.border": "#179299",
                      "info.background": "#fe640b66",
                      "modified": "#df8e1d",
                      "modified.border": "#df8e1d",
                      "modified.background": "#e6e9ef",
                      "predictive": "#acb0be",
                      "predictive.border": "#acb0be",
                      "predictive.background": "#e6e9ef",
                      "renamed": "#209fb5",
                      "renamed.border": "#209fb5",
                      "renamed.background": "#e6e9ef",
                      "success": "#40a02b",
                      "success.border": "#40a02b",
                      "success.background": "#e6e9ef",
                      "unreachable": "#d20f39",
                      "unreachable.border": "#d20f39",
                      "unreachable.background": "#e6e9ef",
                      "warning": "#fe640b",
                      "warning.border": "#fe640b",
                      "warning.background": "#e6e9ef",
                      "players": [
                          {
                              "cursor": "#dc8a78",
                              "selection": "#acb0be80",
                              "background": "#dc8a78"
                          },
                          {
                              "cursor": "#3b6f87",
                              "selection": "#3b6f8733",
                              "background": "#3b6f87"
                          },
                          {
                              "cursor": "#823556",
                              "selection": "#82355633",
                              "background": "#823556"
                          },
                          {
                              "cursor": "#37697c",
                              "selection": "#37697c33",
                              "background": "#37697c"
                          },
                          {
                              "cursor": "#945743",
                              "selection": "#94574333",
                              "background": "#945743"
                          },
                          {
                              "cursor": "#87684b",
                              "selection": "#87684b33",
                              "background": "#87684b"
                          },
                          {
                              "cursor": "#3a58a1",
                              "selection": "#3a58a133",
                              "background": "#3a58a1"
                          },
                          {
                              "cursor": "#486f50",
                              "selection": "#486f5033",
                              "background": "#486f50"
                          }
                      ],
                      "syntax": {
                          "attribute": {
                              "color": "#df8e1d",
                              "font_style": null,
                              "font_weight": null
                          },
                          "boolean": {
                              "color": "#fe640b",
                              "font_style": null,
                              "font_weight": null
                          },
                          "comment": {
                              "color": "#8c8fa1",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "comment.doc": {
                              "color": "#8c8fa1",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "constant": {
                              "color": "#fe640b",
                              "font_style": null,
                              "font_weight": null
                          },
                          "constructor": {
                              "color": "#1e66f5",
                              "font_style": null,
                              "font_weight": null
                          },
                          "embedded": {
                              "color": "#e64553",
                              "font_style": null,
                              "font_weight": null
                          },
                          "emphasis": {
                              "color": "#d20f39",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "emphasis.strong": {
                              "color": "#d20f39",
                              "font_style": null,
                              "font_weight": 700
                          },
                          "enum": {
                              "color": "#179299",
                              "font_style": null,
                              "font_weight": 700
                          },
                          "function": {
                              "color": "#1e66f5",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "hint": {
                              "color": "#179299",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "keyword": {
                              "color": "#8839ef",
                              "font_style": null,
                              "font_weight": null
                          },
                          "link_text": {
                              "color": "#1e66f5",
                              "font_style": null,
                              "font_weight": null
                          },
                          "link_uri": {
                              "color": "#1e66f5",
                              "font_style": null,
                              "font_weight": null
                          },
                          "number": {
                              "color": "#fe640b",
                              "font_style": null,
                              "font_weight": null
                          },
                          "operator": {
                              "color": "#04a5e5",
                              "font_style": null,
                              "font_weight": null
                          },
                          "predictive": {
                              "color": "#acb0be",
                              "font_style": null,
                              "font_weight": null
                          },
                          "predoc": {
                              "color": "#d20f39",
                              "font_style": null,
                              "font_weight": null
                          },
                          "primary": {
                              "color": "#e64553",
                              "font_style": null,
                              "font_weight": null
                          },
                          "property": {
                              "color": "#1e66f5",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation": {
                              "color": "#179299",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.bracket": {
                              "color": "#179299",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.delimiter": {
                              "color": "#7c7f93",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.list_marker": {
                              "color": "#179299",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.special": {
                              "color": "#179299",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.special.symbol": {
                              "color": "#d20f39",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string": {
                              "color": "#40a02b",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string.escape": {
                              "color": "#ea76cb",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string.regex": {
                              "color": "#ea76cb",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string.special": {
                              "color": "#ea76cb",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string.special.symbol": {
                              "color": "#dd7878",
                              "font_style": null,
                              "font_weight": null
                          },
                          "tag": {
                              "color": "#1e66f5",
                              "font_style": null,
                              "font_weight": null
                          },
                          "text.literal": {
                              "color": "#40a02b",
                              "font_style": null,
                              "font_weight": null
                          },
                          "title": {
                              "color": "#4c4f69",
                              "font_style": null,
                              "font_weight": 800
                          },
                          "type": {
                              "color": "#df8e1d",
                              "font_style": null,
                              "font_weight": null
                          },
                          "type.interface": {
                              "color": "#df8e1d",
                              "font_style": null,
                              "font_weight": null
                          },
                          "type.super": {
                              "color": "#df8e1d",
                              "font_style": null,
                              "font_weight": null
                          },
                          "variable": {
                              "color": "#4c4f69",
                              "font_style": null,
                              "font_weight": null
                          },
                          "variable.member": {
                              "color": "#4c4f69",
                              "font_style": null,
                              "font_weight": null
                          },
                          "variable.parameter": {
                              "color": "#fe640b",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "variable.special": {
                              "color": "#823556",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "variant": {
                              "color": "#d20f39",
                              "font_style": null,
                              "font_weight": null
                          }
                      }
                  }
              },
              {
                  "name": "Catppuccin Frappé (peach)",
                  "appearance": "dark",
                  "style": {
                      "background.appearance": "blurred",
                      "border": "#414559",
                      "border.variant": "#cc8d70",
                      "border.focused": "#babbf1",
                      "border.selected": "#ef9f76",
                      "border.transparent": "#a6d189",
                      "border.disabled": "#626880",
                      "elevated_surface.background": "#292c3c",
                      "surface.background": "#303446",
                      "background": "#303446",
                      "element.background": "#232634",
                      "element.hover": "#7379944d",
                      "element.active": "#ef9f7633",
                      "element.selected": "#41455999",
                      "element.disabled": "#737994",
                      "drop_target.background": "#ef9f7666",
                      "ghost_element.background": null,
                      "ghost_element.hover": "#6268804d",
                      "ghost_element.active": "#62688080",
                      "ghost_element.selected": "#73799459",
                      "ghost_element.disabled": "#737994",
                      "text": "#c6d0f5",
                      "text.muted": "#b5bfe2",
                      "text.placeholder": "#626880",
                      "text.disabled": "#737994",
                      "text.accent": "#ef9f76",
                      "icon": "#c6d0f5",
                      "icon.muted": "#838ba7",
                      "icon.disabled": "#737994",
                      "icon.placeholder": "#626880",
                      "icon.accent": "#ef9f76",
                      "status_bar.background": "#232634",
                      "title_bar.background": "#232634",
                      "title_bar.inactive_background": "#232634d9",
                      "toolbar.background": "#303446",
                      "tab_bar.background": "#232634",
                      "tab.inactive_background": "#292c3c",
                      "tab.active_background": "#303446",
                      "search.match_background": "#81c8be33",
                      "panel.background": "#292c3c",
                      "panel.focused_border": "#c6d0f5",
                      "pane.focused_border": "#c6d0f5",
                      "scrollbar.thumb.background": "#ef9f7633",
                      "scrollbar.thumb.hover_background": "#737994",
                      "scrollbar.thumb.border": "#62688080",
                      "scrollbar.track.background": "#303446",
                      "scrollbar.track.border": "#c6d0f512",
                      "editor.foreground": "#c6d0f5",
                      "editor.background": "#303446",
                      "editor.gutter.background": "#303446",
                      "editor.subheader.background": "#292c3c",
                      "editor.active_line.background": "#c6d0f50d",
                      "editor.highlighted_line.background": null,
                      "editor.line_number": "#838ba7",
                      "editor.active_line_number": "#ef9f76",
                      "editor.invisible": "#949cbb66",
                      "editor.wrap_guide": "#626880",
                      "editor.active_wrap_guide": "#626880",
                      "editor.document_highlight.read_background": "#a5adce29",
                      "editor.document_highlight.write_background": "#a5adce29",
                      "terminal.background": "#303446",
                      "terminal.foreground": "#c6d0f5",
                      "terminal.dim_foreground": "#838ba7",
                      "terminal.bright_foreground": "#c6d0f5",
                      "terminal.ansi.black": "#51576d",
                      "terminal.ansi.red": "#e78284",
                      "terminal.ansi.green": "#a6d189",
                      "terminal.ansi.yellow": "#e5c890",
                      "terminal.ansi.blue": "#8caaee",
                      "terminal.ansi.magenta": "#f4b8e4",
                      "terminal.ansi.cyan": "#81c8be",
                      "terminal.ansi.white": "#c6d0f5",
                      "terminal.ansi.bright_black": "#626880",
                      "terminal.ansi.bright_red": "#e78284",
                      "terminal.ansi.bright_green": "#a6d189",
                      "terminal.ansi.bright_yellow": "#e5c890",
                      "terminal.ansi.bright_blue": "#8caaee",
                      "terminal.ansi.bright_magenta": "#f4b8e4",
                      "terminal.ansi.bright_cyan": "#81c8be",
                      "terminal.ansi.bright_white": "#a5adce",
                      "terminal.ansi.dim_black": "#51576d",
                      "terminal.ansi.dim_red": "#e78284",
                      "terminal.ansi.dim_green": "#a6d189",
                      "terminal.ansi.dim_yellow": "#e5c890",
                      "terminal.ansi.dim_blue": "#8caaee",
                      "terminal.ansi.dim_magenta": "#f4b8e4",
                      "terminal.ansi.dim_cyan": "#81c8be",
                      "terminal.ansi.dim_white": "#b5bfe2",
                      "link_text.hover": "#99d1db",
                      "conflict": "#ca9ee6",
                      "conflict.border": "#ca9ee6",
                      "conflict.background": "#292c3c",
                      "created": "#a6d189",
                      "created.border": "#a6d189",
                      "created.background": "#292c3c",
                      "deleted": "#e78284",
                      "deleted.border": "#e78284",
                      "deleted.background": "#292c3c",
                      "error": "#e78284",
                      "error.border": "#e78284",
                      "error.background": "#292c3c",
                      "hidden": "#737994",
                      "hidden.border": "#737994",
                      "hidden.background": "#292c3c",
                      "hint": "#626880",
                      "hint.border": "#626880",
                      "hint.background": "#292c3c",
                      "ignored": "#737994",
                      "ignored.border": "#737994",
                      "ignored.background": "#292c3c",
                      "info": "#81c8be",
                      "info.border": "#81c8be",
                      "info.background": "#ef9f7666",
                      "modified": "#e5c890",
                      "modified.border": "#e5c890",
                      "modified.background": "#292c3c",
                      "predictive": "#626880",
                      "predictive.border": "#626880",
                      "predictive.background": "#292c3c",
                      "renamed": "#85c1dc",
                      "renamed.border": "#85c1dc",
                      "renamed.background": "#292c3c",
                      "success": "#a6d189",
                      "success.border": "#a6d189",
                      "success.background": "#292c3c",
                      "unreachable": "#e78284",
                      "unreachable.border": "#e78284",
                      "unreachable.background": "#292c3c",
                      "warning": "#ef9f76",
                      "warning.border": "#ef9f76",
                      "warning.background": "#292c3c",
                      "players": [
                          {
                              "cursor": "#f2d5cf",
                              "selection": "#62688080",
                              "background": "#f2d5cf"
                          },
                          {
                              "cursor": "#accaeb",
                              "selection": "#accaeb33",
                              "background": "#accaeb"
                          },
                          {
                              "cursor": "#d3b1c8",
                              "selection": "#d3b1c833",
                              "background": "#d3b1c8"
                          },
                          {
                              "cursor": "#abcddf",
                              "selection": "#abcddf33",
                              "background": "#abcddf"
                          },
                          {
                              "cursor": "#d7bdc2",
                              "selection": "#d7bdc233",
                              "background": "#d7bdc2"
                          },
                          {
                              "cursor": "#d3cdcd",
                              "selection": "#d3cdcd33",
                              "background": "#d3cdcd"
                          },
                          {
                              "cursor": "#afc1f2",
                              "selection": "#afc1f233",
                              "background": "#afc1f2"
                          },
                          {
                              "cursor": "#b9d1ca",
                              "selection": "#b9d1ca33",
                              "background": "#b9d1ca"
                          }
                      ],
                      "syntax": {
                          "attribute": {
                              "color": "#e5c890",
                              "font_style": null,
                              "font_weight": null
                          },
                          "boolean": {
                              "color": "#ef9f76",
                              "font_style": null,
                              "font_weight": null
                          },
                          "comment": {
                              "color": "#838ba7",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "comment.doc": {
                              "color": "#838ba7",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "constant": {
                              "color": "#ef9f76",
                              "font_style": null,
                              "font_weight": null
                          },
                          "constructor": {
                              "color": "#8caaee",
                              "font_style": null,
                              "font_weight": null
                          },
                          "embedded": {
                              "color": "#ea999c",
                              "font_style": null,
                              "font_weight": null
                          },
                          "emphasis": {
                              "color": "#e78284",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "emphasis.strong": {
                              "color": "#e78284",
                              "font_style": null,
                              "font_weight": 700
                          },
                          "enum": {
                              "color": "#81c8be",
                              "font_style": null,
                              "font_weight": 700
                          },
                          "function": {
                              "color": "#8caaee",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "hint": {
                              "color": "#81c8be",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "keyword": {
                              "color": "#ca9ee6",
                              "font_style": null,
                              "font_weight": null
                          },
                          "link_text": {
                              "color": "#8caaee",
                              "font_style": null,
                              "font_weight": null
                          },
                          "link_uri": {
                              "color": "#8caaee",
                              "font_style": null,
                              "font_weight": null
                          },
                          "number": {
                              "color": "#ef9f76",
                              "font_style": null,
                              "font_weight": null
                          },
                          "operator": {
                              "color": "#99d1db",
                              "font_style": null,
                              "font_weight": null
                          },
                          "predictive": {
                              "color": "#626880",
                              "font_style": null,
                              "font_weight": null
                          },
                          "predoc": {
                              "color": "#e78284",
                              "font_style": null,
                              "font_weight": null
                          },
                          "primary": {
                              "color": "#ea999c",
                              "font_style": null,
                              "font_weight": null
                          },
                          "property": {
                              "color": "#8caaee",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation": {
                              "color": "#81c8be",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.bracket": {
                              "color": "#81c8be",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.delimiter": {
                              "color": "#949cbb",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.list_marker": {
                              "color": "#81c8be",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.special": {
                              "color": "#81c8be",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.special.symbol": {
                              "color": "#e78284",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string": {
                              "color": "#a6d189",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string.escape": {
                              "color": "#f4b8e4",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string.regex": {
                              "color": "#f4b8e4",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string.special": {
                              "color": "#f4b8e4",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string.special.symbol": {
                              "color": "#eebebe",
                              "font_style": null,
                              "font_weight": null
                          },
                          "tag": {
                              "color": "#8caaee",
                              "font_style": null,
                              "font_weight": null
                          },
                          "text.literal": {
                              "color": "#a6d189",
                              "font_style": null,
                              "font_weight": null
                          },
                          "title": {
                              "color": "#c6d0f5",
                              "font_style": null,
                              "font_weight": 800
                          },
                          "type": {
                              "color": "#e5c890",
                              "font_style": null,
                              "font_weight": null
                          },
                          "type.interface": {
                              "color": "#e5c890",
                              "font_style": null,
                              "font_weight": null
                          },
                          "type.super": {
                              "color": "#e5c890",
                              "font_style": null,
                              "font_weight": null
                          },
                          "variable": {
                              "color": "#c6d0f5",
                              "font_style": null,
                              "font_weight": null
                          },
                          "variable.member": {
                              "color": "#c6d0f5",
                              "font_style": null,
                              "font_weight": null
                          },
                          "variable.parameter": {
                              "color": "#ef9f76",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "variable.special": {
                              "color": "#d3b1c8",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "variant": {
                              "color": "#e78284",
                              "font_style": null,
                              "font_weight": null
                          }
                      }
                  }
              },
              {
                  "name": "Catppuccin Macchiato (peach)",
                  "appearance": "dark",
                  "style": {
                      "background.appearance": "blurred",
                      "border": "#363a4f",
                      "border.variant": "#cf9376",
                      "border.focused": "#b7bdf8",
                      "border.selected": "#f5a97f",
                      "border.transparent": "#a6da95",
                      "border.disabled": "#5b6078",
                      "elevated_surface.background": "#1e2030",
                      "surface.background": "#24273a",
                      "background": "#24273a",
                      "element.background": "#181926",
                      "element.hover": "#6e738d4d",
                      "element.active": "#f5a97f33",
                      "element.selected": "#363a4f99",
                      "element.disabled": "#6e738d",
                      "drop_target.background": "#f5a97f66",
                      "ghost_element.background": null,
                      "ghost_element.hover": "#5b60784d",
                      "ghost_element.active": "#5b607880",
                      "ghost_element.selected": "#6e738d59",
                      "ghost_element.disabled": "#6e738d",
                      "text": "#cad3f5",
                      "text.muted": "#b8c0e0",
                      "text.placeholder": "#5b6078",
                      "text.disabled": "#6e738d",
                      "text.accent": "#f5a97f",
                      "icon": "#cad3f5",
                      "icon.muted": "#8087a2",
                      "icon.disabled": "#6e738d",
                      "icon.placeholder": "#5b6078",
                      "icon.accent": "#f5a97f",
                      "status_bar.background": "#181926",
                      "title_bar.background": "#181926",
                      "title_bar.inactive_background": "#181926d9",
                      "toolbar.background": "#24273a",
                      "tab_bar.background": "#181926",
                      "tab.inactive_background": "#1e2030",
                      "tab.active_background": "#24273a",
                      "search.match_background": "#8bd5ca33",
                      "panel.background": "#1e2030",
                      "panel.focused_border": "#cad3f5",
                      "pane.focused_border": "#cad3f5",
                      "scrollbar.thumb.background": "#f5a97f33",
                      "scrollbar.thumb.hover_background": "#6e738d",
                      "scrollbar.thumb.border": "#5b607880",
                      "scrollbar.track.background": "#24273a",
                      "scrollbar.track.border": "#cad3f512",
                      "editor.foreground": "#cad3f5",
                      "editor.background": "#24273a",
                      "editor.gutter.background": "#24273a",
                      "editor.subheader.background": "#1e2030",
                      "editor.active_line.background": "#cad3f50d",
                      "editor.highlighted_line.background": null,
                      "editor.line_number": "#8087a2",
                      "editor.active_line_number": "#f5a97f",
                      "editor.invisible": "#939ab766",
                      "editor.wrap_guide": "#5b6078",
                      "editor.active_wrap_guide": "#5b6078",
                      "editor.document_highlight.read_background": "#a5adcb29",
                      "editor.document_highlight.write_background": "#a5adcb29",
                      "terminal.background": "#24273a",
                      "terminal.foreground": "#cad3f5",
                      "terminal.dim_foreground": "#8087a2",
                      "terminal.bright_foreground": "#cad3f5",
                      "terminal.ansi.black": "#494d64",
                      "terminal.ansi.red": "#ed8796",
                      "terminal.ansi.green": "#a6da95",
                      "terminal.ansi.yellow": "#eed49f",
                      "terminal.ansi.blue": "#8aadf4",
                      "terminal.ansi.magenta": "#f5bde6",
                      "terminal.ansi.cyan": "#8bd5ca",
                      "terminal.ansi.white": "#cad3f5",
                      "terminal.ansi.bright_black": "#5b6078",
                      "terminal.ansi.bright_red": "#ed8796",
                      "terminal.ansi.bright_green": "#a6da95",
                      "terminal.ansi.bright_yellow": "#eed49f",
                      "terminal.ansi.bright_blue": "#8aadf4",
                      "terminal.ansi.bright_magenta": "#f5bde6",
                      "terminal.ansi.bright_cyan": "#8bd5ca",
                      "terminal.ansi.bright_white": "#a5adcb",
                      "terminal.ansi.dim_black": "#494d64",
                      "terminal.ansi.dim_red": "#ed8796",
                      "terminal.ansi.dim_green": "#a6da95",
                      "terminal.ansi.dim_yellow": "#eed49f",
                      "terminal.ansi.dim_blue": "#8aadf4",
                      "terminal.ansi.dim_magenta": "#f5bde6",
                      "terminal.ansi.dim_cyan": "#8bd5ca",
                      "terminal.ansi.dim_white": "#b8c0e0",
                      "link_text.hover": "#91d7e3",
                      "conflict": "#c6a0f6",
                      "conflict.border": "#c6a0f6",
                      "conflict.background": "#1e2030",
                      "created": "#a6da95",
                      "created.border": "#a6da95",
                      "created.background": "#1e2030",
                      "deleted": "#ed8796",
                      "deleted.border": "#ed8796",
                      "deleted.background": "#1e2030",
                      "error": "#ed8796",
                      "error.border": "#ed8796",
                      "error.background": "#1e2030",
                      "hidden": "#6e738d",
                      "hidden.border": "#6e738d",
                      "hidden.background": "#1e2030",
                      "hint": "#5b6078",
                      "hint.border": "#5b6078",
                      "hint.background": "#1e2030",
                      "ignored": "#6e738d",
                      "ignored.border": "#6e738d",
                      "ignored.background": "#1e2030",
                      "info": "#8bd5ca",
                      "info.border": "#8bd5ca",
                      "info.background": "#f5a97f66",
                      "modified": "#eed49f",
                      "modified.border": "#eed49f",
                      "modified.background": "#1e2030",
                      "predictive": "#5b6078",
                      "predictive.border": "#5b6078",
                      "predictive.background": "#1e2030",
                      "renamed": "#7dc4e4",
                      "renamed.border": "#7dc4e4",
                      "renamed.background": "#1e2030",
                      "success": "#a6da95",
                      "success.border": "#a6da95",
                      "success.background": "#1e2030",
                      "unreachable": "#ed8796",
                      "unreachable.border": "#ed8796",
                      "unreachable.background": "#1e2030",
                      "warning": "#f5a97f",
                      "warning.border": "#f5a97f",
                      "warning.background": "#1e2030",
                      "players": [
                          {
                              "cursor": "#f4dbd6",
                              "selection": "#5b607880",
                              "background": "#f4dbd6"
                          },
                          {
                              "cursor": "#abcdee",
                              "selection": "#abcdee33",
                              "background": "#abcdee"
                          },
                          {
                              "cursor": "#d8b5cf",
                              "selection": "#d8b5cf33",
                              "background": "#d8b5cf"
                          },
                          {
                              "cursor": "#b1d4e4",
                              "selection": "#b1d4e433",
                              "background": "#b1d4e4"
                          },
                          {
                              "cursor": "#dbc3c6",
                              "selection": "#dbc3c633",
                              "background": "#dbc3c6"
                          },
                          {
                              "cursor": "#d8d4d3",
                              "selection": "#d8d4d333",
                              "background": "#d8d4d3"
                          },
                          {
                              "cursor": "#b0c4f5",
                              "selection": "#b0c4f533",
                              "background": "#b0c4f5"
                          },
                          {
                              "cursor": "#bbd6cf",
                              "selection": "#bbd6cf33",
                              "background": "#bbd6cf"
                          }
                      ],
                      "syntax": {
                          "attribute": {
                              "color": "#eed49f",
                              "font_style": null,
                              "font_weight": null
                          },
                          "boolean": {
                              "color": "#f5a97f",
                              "font_style": null,
                              "font_weight": null
                          },
                          "comment": {
                              "color": "#8087a2",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "comment.doc": {
                              "color": "#8087a2",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "constant": {
                              "color": "#f5a97f",
                              "font_style": null,
                              "font_weight": null
                          },
                          "constructor": {
                              "color": "#8aadf4",
                              "font_style": null,
                              "font_weight": null
                          },
                          "embedded": {
                              "color": "#ee99a0",
                              "font_style": null,
                              "font_weight": null
                          },
                          "emphasis": {
                              "color": "#ed8796",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "emphasis.strong": {
                              "color": "#ed8796",
                              "font_style": null,
                              "font_weight": 700
                          },
                          "enum": {
                              "color": "#8bd5ca",
                              "font_style": null,
                              "font_weight": 700
                          },
                          "function": {
                              "color": "#8aadf4",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "hint": {
                              "color": "#8bd5ca",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "keyword": {
                              "color": "#c6a0f6",
                              "font_style": null,
                              "font_weight": null
                          },
                          "link_text": {
                              "color": "#8aadf4",
                              "font_style": null,
                              "font_weight": null
                          },
                          "link_uri": {
                              "color": "#8aadf4",
                              "font_style": null,
                              "font_weight": null
                          },
                          "number": {
                              "color": "#f5a97f",
                              "font_style": null,
                              "font_weight": null
                          },
                          "operator": {
                              "color": "#91d7e3",
                              "font_style": null,
                              "font_weight": null
                          },
                          "predictive": {
                              "color": "#5b6078",
                              "font_style": null,
                              "font_weight": null
                          },
                          "predoc": {
                              "color": "#ed8796",
                              "font_style": null,
                              "font_weight": null
                          },
                          "primary": {
                              "color": "#ee99a0",
                              "font_style": null,
                              "font_weight": null
                          },
                          "property": {
                              "color": "#8aadf4",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation": {
                              "color": "#8bd5ca",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.bracket": {
                              "color": "#8bd5ca",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.delimiter": {
                              "color": "#939ab7",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.list_marker": {
                              "color": "#8bd5ca",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.special": {
                              "color": "#8bd5ca",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.special.symbol": {
                              "color": "#ed8796",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string": {
                              "color": "#a6da95",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string.escape": {
                              "color": "#f5bde6",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string.regex": {
                              "color": "#f5bde6",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string.special": {
                              "color": "#f5bde6",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string.special.symbol": {
                              "color": "#f0c6c6",
                              "font_style": null,
                              "font_weight": null
                          },
                          "tag": {
                              "color": "#8aadf4",
                              "font_style": null,
                              "font_weight": null
                          },
                          "text.literal": {
                              "color": "#a6da95",
                              "font_style": null,
                              "font_weight": null
                          },
                          "title": {
                              "color": "#cad3f5",
                              "font_style": null,
                              "font_weight": 800
                          },
                          "type": {
                              "color": "#eed49f",
                              "font_style": null,
                              "font_weight": null
                          },
                          "type.interface": {
                              "color": "#eed49f",
                              "font_style": null,
                              "font_weight": null
                          },
                          "type.super": {
                              "color": "#eed49f",
                              "font_style": null,
                              "font_weight": null
                          },
                          "variable": {
                              "color": "#cad3f5",
                              "font_style": null,
                              "font_weight": null
                          },
                          "variable.member": {
                              "color": "#cad3f5",
                              "font_style": null,
                              "font_weight": null
                          },
                          "variable.parameter": {
                              "color": "#f5a97f",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "variable.special": {
                              "color": "#d8b5cf",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "variant": {
                              "color": "#ed8796",
                              "font_style": null,
                              "font_weight": null
                          }
                      }
                  }
              },
              {
                  "name": "Catppuccin Mocha (peach)",
                  "appearance": "dark",
                  "style": {
                      "background.appearance": "blurred",
                      "border": "#313244",
                      "border.variant": "#d2997a",
                      "border.focused": "#b4befe",
                      "border.selected": "#fab387",
                      "border.transparent": "#a6e3a1",
                      "border.disabled": "#585b70",
                      "elevated_surface.background": "#181825",
                      "surface.background": "#1e1e2e",
                      "background": "#1e1e2e",
                      "element.background": "#11111b",
                      "element.hover": "#6c70864d",
                      "element.active": "#fab38733",
                      "element.selected": "#31324499",
                      "element.disabled": "#6c7086",
                      "drop_target.background": "#fab38766",
                      "ghost_element.background": null,
                      "ghost_element.hover": "#585b704d",
                      "ghost_element.active": "#585b7080",
                      "ghost_element.selected": "#6c708659",
                      "ghost_element.disabled": "#6c7086",
                      "text": "#cdd6f4",
                      "text.muted": "#bac2de",
                      "text.placeholder": "#585b70",
                      "text.disabled": "#6c7086",
                      "text.accent": "#fab387",
                      "icon": "#cdd6f4",
                      "icon.muted": "#7f849c",
                      "icon.disabled": "#6c7086",
                      "icon.placeholder": "#585b70",
                      "icon.accent": "#fab387",
                      "status_bar.background": "#11111b",
                      "title_bar.background": "#11111b",
                      "title_bar.inactive_background": "#11111bd9",
                      "toolbar.background": "#1e1e2e",
                      "tab_bar.background": "#11111b",
                      "tab.inactive_background": "#181825",
                      "tab.active_background": "#1e1e2e",
                      "search.match_background": "#94e2d533",
                      "panel.background": "#181825",
                      "panel.focused_border": "#cdd6f4",
                      "pane.focused_border": "#cdd6f4",
                      "scrollbar.thumb.background": "#fab38733",
                      "scrollbar.thumb.hover_background": "#6c7086",
                      "scrollbar.thumb.border": "#585b7080",
                      "scrollbar.track.background": "#1e1e2e",
                      "scrollbar.track.border": "#cdd6f412",
                      "editor.foreground": "#cdd6f4",
                      "editor.background": "#1e1e2e",
                      "editor.gutter.background": "#1e1e2e",
                      "editor.subheader.background": "#181825",
                      "editor.active_line.background": "#cdd6f40d",
                      "editor.highlighted_line.background": null,
                      "editor.line_number": "#7f849c",
                      "editor.active_line_number": "#fab387",
                      "editor.invisible": "#9399b266",
                      "editor.wrap_guide": "#585b70",
                      "editor.active_wrap_guide": "#585b70",
                      "editor.document_highlight.read_background": "#a6adc829",
                      "editor.document_highlight.write_background": "#a6adc829",
                      "terminal.background": "#1e1e2e",
                      "terminal.foreground": "#cdd6f4",
                      "terminal.dim_foreground": "#7f849c",
                      "terminal.bright_foreground": "#cdd6f4",
                      "terminal.ansi.black": "#45475a",
                      "terminal.ansi.red": "#f38ba8",
                      "terminal.ansi.green": "#a6e3a1",
                      "terminal.ansi.yellow": "#f9e2af",
                      "terminal.ansi.blue": "#89b4fa",
                      "terminal.ansi.magenta": "#f5c2e7",
                      "terminal.ansi.cyan": "#94e2d5",
                      "terminal.ansi.white": "#cdd6f4",
                      "terminal.ansi.bright_black": "#585b70",
                      "terminal.ansi.bright_red": "#f38ba8",
                      "terminal.ansi.bright_green": "#a6e3a1",
                      "terminal.ansi.bright_yellow": "#f9e2af",
                      "terminal.ansi.bright_blue": "#89b4fa",
                      "terminal.ansi.bright_magenta": "#f5c2e7",
                      "terminal.ansi.bright_cyan": "#94e2d5",
                      "terminal.ansi.bright_white": "#a6adc8",
                      "terminal.ansi.dim_black": "#45475a",
                      "terminal.ansi.dim_red": "#f38ba8",
                      "terminal.ansi.dim_green": "#a6e3a1",
                      "terminal.ansi.dim_yellow": "#f9e2af",
                      "terminal.ansi.dim_blue": "#89b4fa",
                      "terminal.ansi.dim_magenta": "#f5c2e7",
                      "terminal.ansi.dim_cyan": "#94e2d5",
                      "terminal.ansi.dim_white": "#bac2de",
                      "link_text.hover": "#89dceb",
                      "conflict": "#cba6f7",
                      "conflict.border": "#cba6f7",
                      "conflict.background": "#181825",
                      "created": "#a6e3a1",
                      "created.border": "#a6e3a1",
                      "created.background": "#181825",
                      "deleted": "#f38ba8",
                      "deleted.border": "#f38ba8",
                      "deleted.background": "#181825",
                      "error": "#f38ba8",
                      "error.border": "#f38ba8",
                      "error.background": "#181825",
                      "hidden": "#6c7086",
                      "hidden.border": "#6c7086",
                      "hidden.background": "#181825",
                      "hint": "#585b70",
                      "hint.border": "#585b70",
                      "hint.background": "#181825",
                      "ignored": "#6c7086",
                      "ignored.border": "#6c7086",
                      "ignored.background": "#181825",
                      "info": "#94e2d5",
                      "info.border": "#94e2d5",
                      "info.background": "#fab38766",
                      "modified": "#f9e2af",
                      "modified.border": "#f9e2af",
                      "modified.background": "#181825",
                      "predictive": "#585b70",
                      "predictive.border": "#585b70",
                      "predictive.background": "#181825",
                      "renamed": "#74c7ec",
                      "renamed.border": "#74c7ec",
                      "renamed.background": "#181825",
                      "success": "#a6e3a1",
                      "success.border": "#a6e3a1",
                      "success.background": "#181825",
                      "unreachable": "#f38ba8",
                      "unreachable.border": "#f38ba8",
                      "unreachable.background": "#181825",
                      "warning": "#fab387",
                      "warning.border": "#fab387",
                      "warning.background": "#181825",
                      "players": [
                          {
                              "cursor": "#f5e0dc",
                              "selection": "#585b7080",
                              "background": "#f5e0dc"
                          },
                          {
                              "cursor": "#a9d0f0",
                              "selection": "#a9d0f033",
                              "background": "#a9d0f0"
                          },
                          {
                              "cursor": "#dcb8d5",
                              "selection": "#dcb8d533",
                              "background": "#dcb8d5"
                          },
                          {
                              "cursor": "#b6dae7",
                              "selection": "#b6dae733",
                              "background": "#b6dae7"
                          },
                          {
                              "cursor": "#dfc8c8",
                              "selection": "#dfc8c833",
                              "background": "#dfc8c8"
                          },
                          {
                              "cursor": "#dfdad8",
                              "selection": "#dfdad833",
                              "background": "#dfdad8"
                          },
                          {
                              "cursor": "#b2c8f6",
                              "selection": "#b2c8f633",
                              "background": "#b2c8f6"
                          },
                          {
                              "cursor": "#bddbd2",
                              "selection": "#bddbd233",
                              "background": "#bddbd2"
                          }
                      ],
                      "syntax": {
                          "attribute": {
                              "color": "#f9e2af",
                              "font_style": null,
                              "font_weight": null
                          },
                          "boolean": {
                              "color": "#fab387",
                              "font_style": null,
                              "font_weight": null
                          },
                          "comment": {
                              "color": "#7f849c",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "comment.doc": {
                              "color": "#7f849c",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "constant": {
                              "color": "#fab387",
                              "font_style": null,
                              "font_weight": null
                          },
                          "constructor": {
                              "color": "#89b4fa",
                              "font_style": null,
                              "font_weight": null
                          },
                          "embedded": {
                              "color": "#eba0ac",
                              "font_style": null,
                              "font_weight": null
                          },
                          "emphasis": {
                              "color": "#f38ba8",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "emphasis.strong": {
                              "color": "#f38ba8",
                              "font_style": null,
                              "font_weight": 700
                          },
                          "enum": {
                              "color": "#94e2d5",
                              "font_style": null,
                              "font_weight": 700
                          },
                          "function": {
                              "color": "#89b4fa",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "hint": {
                              "color": "#94e2d5",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "keyword": {
                              "color": "#cba6f7",
                              "font_style": null,
                              "font_weight": null
                          },
                          "link_text": {
                              "color": "#89b4fa",
                              "font_style": null,
                              "font_weight": null
                          },
                          "link_uri": {
                              "color": "#89b4fa",
                              "font_style": null,
                              "font_weight": null
                          },
                          "number": {
                              "color": "#fab387",
                              "font_style": null,
                              "font_weight": null
                          },
                          "operator": {
                              "color": "#89dceb",
                              "font_style": null,
                              "font_weight": null
                          },
                          "predictive": {
                              "color": "#585b70",
                              "font_style": null,
                              "font_weight": null
                          },
                          "predoc": {
                              "color": "#f38ba8",
                              "font_style": null,
                              "font_weight": null
                          },
                          "primary": {
                              "color": "#eba0ac",
                              "font_style": null,
                              "font_weight": null
                          },
                          "property": {
                              "color": "#89b4fa",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation": {
                              "color": "#94e2d5",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.bracket": {
                              "color": "#94e2d5",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.delimiter": {
                              "color": "#9399b2",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.list_marker": {
                              "color": "#94e2d5",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.special": {
                              "color": "#94e2d5",
                              "font_style": null,
                              "font_weight": null
                          },
                          "punctuation.special.symbol": {
                              "color": "#f38ba8",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string": {
                              "color": "#a6e3a1",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string.escape": {
                              "color": "#f5c2e7",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string.regex": {
                              "color": "#f5c2e7",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string.special": {
                              "color": "#f5c2e7",
                              "font_style": null,
                              "font_weight": null
                          },
                          "string.special.symbol": {
                              "color": "#f2cdcd",
                              "font_style": null,
                              "font_weight": null
                          },
                          "tag": {
                              "color": "#89b4fa",
                              "font_style": null,
                              "font_weight": null
                          },
                          "text.literal": {
                              "color": "#a6e3a1",
                              "font_style": null,
                              "font_weight": null
                          },
                          "title": {
                              "color": "#cdd6f4",
                              "font_style": null,
                              "font_weight": 800
                          },
                          "type": {
                              "color": "#f9e2af",
                              "font_style": null,
                              "font_weight": null
                          },
                          "type.interface": {
                              "color": "#f9e2af",
                              "font_style": null,
                              "font_weight": null
                          },
                          "type.super": {
                              "color": "#f9e2af",
                              "font_style": null,
                              "font_weight": null
                          },
                          "variable": {
                              "color": "#cdd6f4",
                              "font_style": null,
                              "font_weight": null
                          },
                          "variable.member": {
                              "color": "#cdd6f4",
                              "font_style": null,
                              "font_weight": null
                          },
                          "variable.parameter": {
                              "color": "#fab387",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "variable.special": {
                              "color": "#dcb8d5",
                              "font_style": "italic",
                              "font_weight": null
                          },
                          "variant": {
                              "color": "#f38ba8",
                              "font_style": null,
                              "font_weight": null
                          }
                      }
                  }
              }
          ]
      }
    '';
  };
}
