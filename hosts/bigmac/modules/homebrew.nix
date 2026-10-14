# The Homebrew apps only BigMac gets, on top of the shared list in
# modules/darwin/homebrew.nix (which also holds the policy). nix-darwin
# merges the two, and a cleanup on BigMac keeps what either one lists.
{...}: {
  homebrew = {
    taps = [
      {
        name = "xykong/tap";
        trusted = true;
      }
    ];

    casks = [
      "affinity-designer"
      "affinity-photo"
      "affinity-publisher"
      "asana"
      "atuin-desktop"
      "chatgpt"
      "downie"
      "dropzone"
      "expressvpn"
      "xykong/tap/flux-markdown"
      "geekbench"
      "keymapp"
      "klokki"
      "ledger-wallet"
      "loopback"
      "motrix"
      "notunes"
      "onyx"
      "qflipper"
      "renamer"
      "soundsource"
      "steermouse"
    ];

    # Installing these needs an App Store sign-in on the Mac.
    masApps = {
      "1Password for Safari" = 1569813296;
      "Color Picker" = 1545870783;
      "Compressor" = 424390742;
      "DigiDoc4" = 1370791134;
      "Dropover" = 1355679052;
      "ExcalidrawZ" = 6636493997;
      "Final Cut Pro" = 424389933;
      "Gapplin" = 768053424;
      "Keynote" = 409183694;
      "Keystroke Pro" = 1572206224;
      "Motion" = 434290957;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "RunCatNeo" = 6757801838;
      "Web eID" = 1576665083;
    };
  };
}
