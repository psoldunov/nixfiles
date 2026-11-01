# Alan Wake saves, kept in step by Syncthing through BigTasty. Whopper and
# ShackStack play the Epic copies through Heroic with GE-Proton, one wine
# prefix per game named after its title, so each save directory sits at the
# same place inside a host's prefix root (`heroicPrefixes`). BigTasty is
# always on and keeps its own copy under `storageDir`. The players share the
# folders with BigTasty only, never with each other, so every save passes
# through it, and a save made on one machine reaches the other even when the
# two are never on at the same time.
#
# Ignore patterns keep the files that belong to one machine local:
# Remastered's resolution.xml, and Alan Wake 2's renderer.ini (resolution,
# window mode, graphics quality), LSAO/ (lighting caches built per
# resolution), cache/ and eos.log. The rest syncs on purpose. Remastered's
# `config` stores the collectibles next to its options, and Alan Wake 2's
# preferences container stores the upgrades next to the audio and gameplay
# options.
#
# Staggered versioning keeps old copies of every changed or deleted file in
# each folder's .stversions, in case a sync overwrites a save: one per 30
# seconds for the first hour, one per hour for a day, one per day for 30
# days, then one per week for a year. Keeping a fixed count was not enough:
# Remastered rewrites `config` about once a minute, which pushed every older
# copy out within minutes.
{
  config,
  lib,
  ...
}: let
  cfg = config.gameSaves;

  games = {
    AlanWakeRemastered = {
      id = "alan-wake-remastered";
      title = "Alan Wake Remastered";
      inPrefix = "Documents/Remedy/AlanWakeRemastered";
      ignorePatterns = ["/resolution.xml"];
    };
    AlanWake2 = {
      id = "alan-wake-2";
      title = "Alan Wake 2";
      inPrefix = "AppData/Local/Remedy/AlanWake2";
      ignorePatterns = [
        "/renderer.ini"
        "/LSAO"
        "/cache"
        "/eos.log"
      ];
    };
  };

  pathFor = game:
    if cfg.heroicPrefixes != null
    then "${cfg.heroicPrefixes}/${game.title}/drive_c/users/steamuser/${game.inPrefix}"
    else "${cfg.storageDir}/${game.title} Saves";
in {
  options.gameSaves = {
    heroicPrefixes = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/home/psoldunov/Games/Heroic/Prefixes";
      description = "On a host that plays the games: the directory holding Heroic's per-game wine prefixes.";
    };
    storageDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/RAID/apps/syncthing";
      description = "On a host that only stores the saves: the directory that gets one `<title> Saves` subdirectory per game.";
    };
    devices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Syncthing devices, by name, that share the saves.";
    };
  };

  config = {
    assertions = [
      {
        assertion = (cfg.heroicPrefixes == null) != (cfg.storageDir == null);
        message = "gameSaves: set exactly one of heroicPrefixes and storageDir.";
      }
    ];

    services.syncthing.settings.folders =
      lib.mapAttrs (_: game: {
        inherit (game) id ignorePatterns;
        inherit (cfg) devices;
        label = game.title;
        path = pathFor game;
        versioning = {
          type = "staggered";
          params.maxAge = toString (365 * 24 * 60 * 60);
        };
      })
      games;
  };
}
