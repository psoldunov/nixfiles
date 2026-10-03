{
  # Google Chrome is proprietary, so home-manager manages no extensions or
  # dictionaries for it; those sync through the Google account instead.
  programs.google-chrome.enable = true;
}
