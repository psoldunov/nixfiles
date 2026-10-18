# zsh, the login shell on every host, set up to work like fish: commands
# are coloured as you type, grey suggestions come from history (Atuin's
# first, which `atuin init zsh` arranges), Tab opens a fuzzy menu
# (fzf-tab), and the keys behave as they do in fish. The prompt, Ctrl-R,
# `j`, `y` and the fzf widgets come from the integrations in ./shell.nix,
# which reach zsh like the other shells. Fish stays installed next to it.
{
  hostConfig,
  lib,
  pkgs,
  ...
}: let
  isDesktop = hostConfig.role == "desktop";
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinuxDesktop = isDesktop && !isDarwin;
in {
  # Completion definitions zsh itself lacks, closer to what fish ships.
  home.packages = [pkgs.zsh-completions];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # Typing a directory's name cds into it, as in fish.
    autocd = true;
    # zsh picks vi mode when $EDITOR mentions vi; fish's keys are emacs-style.
    defaultKeymap = "emacs";
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;

    history = {
      size = 100000;
      save = 100000;
      ignoreAllDups = true;
      expireDuplicatesFirst = true;
      extended = true;
    };

    setOptions = [
      # cd keeps a directory stack, like fish's prevd/nextd: `cd -<Tab>`.
      "AUTO_PUSHD"
      "PUSHD_IGNORE_DUPS"
      "PUSHD_SILENT"
      # Complete at the cursor, not only at the end of the word.
      "COMPLETE_IN_WORD"
      "ALWAYS_TO_END"
      # `# comment` on the command line, as in fish.
      "INTERACTIVE_COMMENTS"
      "NO_BEEP"
    ];

    # Without `/`, Alt-Backspace and Ctrl-W delete one path component.
    localVariables.WORDCHARS = "*?_-.[]~=&;!#$%^(){}<>";

    shellAliases.reload = "exec zsh";

    # The fish functions from ./shell.nix.
    siteFunctions =
      {
        mkcd = ''mkdir -p -- "$1" && cd -- "$1"'';
      }
      // lib.optionalAttrs isDesktop {
        fzf_kill = ''
          local pids
          pids=$(ps aux | fzf --multi --header-lines=1 | awk '{print $2}')
          [[ -n $pids ]] && kill -9 ''${=pids}
        '';
      }
      # macOS ships its own open(1).
      // lib.optionalAttrs isLinuxDesktop {
        open = ''xdg-open "$@" &>/dev/null &!'';
      };

    initContent = lib.mkMerge [
      # fzf-tab loads after compinit (order 570) and before the plugins that
      # wrap widgets: autosuggestions (700) and syntax highlighting (1200).
      # fzf's own Tab handler (910) falls back to it.
      (lib.mkOrder 600 ''
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

        # Case-insensitive, then partial words (f-b -> foo-bar), then substrings.
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
        # fzf-tab shows these as group headers; < and > switch between groups.
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':completion:*' menu no
        zstyle ':completion:*:git-checkout:*' sort false
        zstyle ':fzf-tab:*' switch-group '<' '>'
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd -1 --color=always $realpath'
      '')

      ''
        # Keys zsh leaves unbound or binds differently from fish.
        bindkey '^[[H' beginning-of-line  # Home
        bindkey '^[OH' beginning-of-line
        bindkey '^[[F' end-of-line        # End
        bindkey '^[OF' end-of-line
        bindkey '^[[3~' delete-char       # Delete
        bindkey '^[[3;5~' kill-word       # Ctrl-Delete
        # Ctrl/Alt-Right also take one word of a suggestion, Right takes all of it.
        bindkey '^[[1;5D' backward-word   # Ctrl-Left
        bindkey '^[[1;5C' forward-word    # Ctrl-Right
        bindkey '^[[1;3D' backward-word   # Alt-Left
        bindkey '^[[1;3C' forward-word    # Alt-Right

        # Alt-E edits the command line in $EDITOR.
        autoload -Uz edit-command-line
        zle -N edit-command-line
        bindkey '^[e' edit-command-line

        # Alt-S adds or removes sudo at the start of the line. On an empty
        # line it works on the previous command.
        _toggle_sudo() {
          [[ -z $BUFFER ]] && zle up-history
          if [[ $BUFFER == sudo\ * ]]; then
            BUFFER=''${BUFFER#sudo }
          else
            BUFFER="sudo $BUFFER"
          fi
          zle end-of-line
        }
        zle -N _toggle_sudo
        bindkey '^[s' _toggle_sudo
      ''
    ];
  };
}
