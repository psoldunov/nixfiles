{...}: {
  # User-level mirror of the system mime defaults. Both this file and
  # hosts/whopper/modules/desktop-environment.nix read the same list from
  # hosts/whopper/mime-defaults.nix.
  #
  # Why: sandboxed apps (notably Steam's bwrap FHS env) replace /etc with
  # their own rootfs, so the host's /etc/xdg/mimeapps.list is invisible.
  # Only ~/.config/mimeapps.list is reachable through the bind-mounted
  # home directory, so any defaults we want Steam etc. to honor must live
  # here too. Without this, Steam's "Browse local files" falls back to
  # $TERMINAL (kitty) because no inode/directory handler is found.
  #
  # Plasma's "Default Applications" KCM and several GTK apps rewrite
  # ~/.config/mimeapps.list in place, which turns the home-manager symlink into
  # a real file and made every rebuild fail on a stale .hm-backup. Take
  # ownership outright instead: the list below is authoritative, so anything an
  # app registers into [Added Associations] at runtime is discarded on rebuild.
  # Consequence: a handler that only ever existed at runtime must be declared
  # in mime-defaults.nix or it is lost (slack, plexamp and cider-2 all
  # registered their scheme handlers that way).
  xdg.configFile."mimeapps.list".force = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = import ../../mime-defaults.nix;
  };
}
