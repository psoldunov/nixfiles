# The Homebrew apps only MacFlurry gets, on top of the shared list in
# modules/darwin/homebrew.nix (which also holds the policy). Empty for now:
# the laptop runs the shared set and nothing else, so a cleanup on it
# removes every other cask. A laptop-only app goes here, not in the shared
# list, so BigMac doesn't pick it up.
{...}: {
  homebrew = {
    casks = [];

    # Installing these needs an App Store sign-in on the Mac.
    masApps = {};
  };
}
