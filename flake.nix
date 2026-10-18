{
  description = "Whopper Configuration ST";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    catppuccin-vsc.url = "https://flakehub.com/f/catppuccin/vscode/*.tar.gz";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    catppuccin = {
      url = "github:catppuccin/nix";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative partitioning. BigKing's NVMe layout (hosts/bigking/disko.nix),
    # which nixos-anywhere creates when installing it.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # BigKing's ASUSTOR hardware (hosts/bigking/modules/asustor): kernel
    # drivers for the fan, LEDs and buttons, and the LCD daemon's source.
    asustor-platform-driver = {
      url = "github:mafredri/asustor-platform-driver";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lcm = {
      url = "github:mafredri/lcm";
      flake = false;
    };

    nix-gaming.url = "github:fufexan/nix-gaming";

    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS system layer for the Macs (darwinConfigurations.{BigMac,MacFlurry}).
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    steam-presence = {
      url = "github:JustTemmie/steam-presence";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    context-mode = {
      url = "github:mksglu/context-mode";
      flake = false;
    };

    caveman = {
      url = "github:juliusbrussee/caveman";
      flake = false;
    };

    impeccable = {
      url = "github:pbakaus/impeccable";
      flake = false;
    };

    taste-skill = {
      url = "github:leonxlnx/taste-skill";
      flake = false;
    };

    i-have-adhd = {
      url = "github:ayghri/i-have-adhd";
      flake = false;
    };

    playwright-cli = {
      url = "github:microsoft/playwright-cli";
      flake = false;
    };

    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };

    # REA's reverse-engineer-anything skill, pinned to a release tag. The rea
    # MCP server in modules/home/programs/claude-code/mcp.nix runs the npm
    # release named by this checkout's package.json, so both move together.
    # Bump: edit the tag, then `nix flake update rea`.
    rea = {
      url = "github:morluto/rea/rea-agents-6.4.0";
      flake = false;
    };

    skrepka = {
      url = "github:psoldunov/skrepka/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ensemblr = {
      url = "github:ensemblr-hq/ensemblr/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    token-station = {
      url = "github:psoldunov/token-station/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager is only used by wye's own module-evaluation check.
    wye = {
      url = "github:psoldunov/wye/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Source for overlays/solaar.nix. Bump with `nix flake update solaar`.
    solaar = {
      url = "github:psoldunov/Solaar/master";
      flake = false;
    };

    # Figma desktop client. Used by hosts/whopper/home/programs/figma.nix.
    # Bump with `nix flake update figma`. The repo is private: fetching it
    # needs the GitHub token wired in hosts/whopper/modules/nix.nix.
    figma = {
      url = "github:psoldunov/figma/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Linear desktop client. Used by hosts/whopper/home/programs/linear.nix.
    # Bump with `nix flake update linear`. The repo is private: fetching it
    # needs the GitHub token wired in hosts/whopper/modules/nix.nix.
    linear = {
      url = "github:psoldunov/linear/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Notion desktop client. Used by hosts/whopper/home/programs/notion.nix.
    # Bump with `nix flake update notion`. The repo is private: fetching it
    # needs the GitHub token wired in hosts/whopper/modules/nix.nix.
    notion = {
      url = "github:psoldunov/notion/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Notion Calendar desktop client. Used by
    # hosts/whopper/home/programs/notion-calendar.nix. Bump with
    # `nix flake update notion-calendar`. The repo is private: fetching it
    # needs the GitHub token wired in hosts/whopper/modules/nix.nix.
    notion-calendar = {
      url = "github:psoldunov/notion-calendar/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Concierge: Claude for work outside code repositories. Used by
    # hosts/whopper/home/programs/concierge.nix (app + daemon) and
    # hosts/bigtasty/modules/services/concierge-server.nix (Sync server). Bump with
    # `nix flake update concierge`. The repo is private: fetching it needs the
    # GitHub token wired in hosts/whopper/modules/nix.nix.
    concierge = {
      url = "github:psoldunov/concierge/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Numero, the Numi-style text calculator. Used by
    # hosts/whopper/home/programs/numero.nix. Bump with
    # `nix flake update numero`. Its flake packages Linux only.
    numero = {
      url = "github:psoldunov/numero/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Clokkr, the tray time tracker. Used by
    # hosts/whopper/home/programs/clokkr.nix. Bump with
    # `nix flake update clokkr`. The repo is private: fetching it needs the
    # GitHub token wired in hosts/whopper/modules/nix.nix.
    clokkr = {
      url = "github:psoldunov/clokkr/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    zen-browser,
    vscode-server,
    nixpkgs-stable,
    catppuccin,
    nix-gaming,
    sops-nix,
    disko,
    home-manager,
    nix-darwin,
    apple-fonts,
    plasma-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;

    system = "x86_64-linux";
    darwinSystem = "aarch64-darwin";

    mkPkgsStable = system:
      import nixpkgs-stable {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

    pkgs-stable = mkPkgsStable system;

    appleFonts = apple-fonts.packages.${system};

    mkHost = import ./lib/mkHost.nix {inherit nixpkgs;};
    mkDarwinHost = import ./lib/mkDarwinHost.nix {inherit nix-darwin;};

    # Every Mac is wired the same way; only its hosts/<dir> differs.
    mkMac = dir: let
      hostConfig = import ./hosts/${dir}/hostConfig.nix;
      pkgs-stable = mkPkgsStable darwinSystem;
    in
      mkDarwinHost {
        specialArgs = {
          inherit
            inputs
            outputs
            hostConfig
            pkgs-stable
            ;
        };
        modules = [
          ./hosts/${dir}/default.nix
          sops-nix.darwinModules.sops
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              extraSpecialArgs = {
                inherit
                  inputs
                  outputs
                  hostConfig
                  pkgs-stable
                  ;
              };
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              # Same reason as on Whopper: apps rewrite some HM-owned files.
              overwriteBackup = true;
              users = {
                psoldunov = import ./hosts/${dir}/home;
              };
              sharedModules = [
                sops-nix.homeManagerModules.sops
              ];
            };
          }
        ];
      };
  in {
    formatter = nixpkgs.lib.genAttrs [system darwinSystem] (
      s: nixpkgs.legacyPackages.${s}.alejandra
    );

    nixosConfigurations.Whopper = mkHost {
      inherit system;
      specialArgs = {
        inherit
          inputs
          outputs
          appleFonts
          pkgs-stable
          ;
        hostConfig = import ./hosts/whopper/hostConfig.nix;
      };
      modules = [
        ./hosts/whopper/default.nix
        nix-gaming.nixosModules.pipewireLowLatency
        nix-gaming.nixosModules.platformOptimizations
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        vscode-server.nixosModules.default
        catppuccin.nixosModules.catppuccin
        {
          home-manager = {
            extraSpecialArgs = {
              inherit
                inputs
                outputs
                pkgs-stable
                ;
              hostConfig = import ./hosts/whopper/hostConfig.nix;
            };
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-backup";
            # Desktop apps rewrite some home-manager-owned files at runtime
            # (~/.config/mimeapps.list, ~/.gtkrc-2.0). Activation then wants to
            # back the file up, finds a stale <file>.hm-backup from the previous
            # rebuild, and aborts with "would be clobbered". Overwrite the stale
            # backup instead of failing — the authoritative copy is in the store.
            overwriteBackup = true;
            users = {
              psoldunov =
                import ./hosts/whopper/home;
            };
            sharedModules = [
              sops-nix.homeManagerModules.sops
              catppuccin.homeModules.catppuccin
              plasma-manager.homeModules.plasma-manager
              (
                {pkgs, ...}: let
                  zen = zen-browser.packages."${system}";
                  # zen-browser-flake's bot hashed 1.23.3b before Zen published
                  # the release (youwen5/zen-browser-flake#22). The hash below is
                  # GitHub's digest of the published asset. Applies to 1.23.3b
                  # only, so the next version bump drops it on its own.
                  zen-unwrapped =
                    if zen.zen-browser-unwrapped.version == "1.23.3b"
                    then
                      zen.zen-browser-unwrapped.overrideAttrs {
                        src = pkgs.fetchurl {
                          url = "https://github.com/zen-browser/desktop/releases/download/1.23.3b/zen.linux-x86_64.tar.xz";
                          hash = "sha256-uyBF0+IWVNQP6EElAJLurf0sH8gx7vtQkiJ3PIvcoUk=";
                        };
                      }
                    else zen.zen-browser-unwrapped;
                in {
                  home.packages = [
                    (zen.default.override {zen-browser-unwrapped = zen-unwrapped;})
                  ];
                }
              )
            ];
          };
        }
      ];
    };

    nixosConfigurations.BigTasty = mkHost {
      inherit system;
      specialArgs = {
        inherit
          inputs
          outputs
          pkgs-stable
          ;
        hostConfig = import ./hosts/bigtasty/hostConfig.nix;
      };
      modules = [
        ./hosts/bigtasty/default.nix
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        vscode-server.nixosModules.default
        ({...}: {
          services.vscode-server.enable = true;
        })
        {
          home-manager = {
            extraSpecialArgs = {
              inherit
                inputs
                outputs
                pkgs-stable
                ;
              hostConfig = import ./hosts/bigtasty/hostConfig.nix;
            };
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-backup";
            # Desktop apps rewrite some home-manager-owned files at runtime
            # (~/.config/mimeapps.list, ~/.gtkrc-2.0). Activation then wants to
            # back the file up, finds a stale <file>.hm-backup from the previous
            # rebuild, and aborts with "would be clobbered". Overwrite the stale
            # backup instead of failing — the authoritative copy is in the store.
            overwriteBackup = true;
            users = {
              psoldunov = import ./hosts/bigtasty/home/home.nix;
            };
            sharedModules = [
              sops-nix.homeManagerModules.sops
            ];
          };
        }
      ];
    };

    # The NAS (ASUSTOR AS6604T). First installed over ADM with nixos-anywhere,
    # see hosts/bigking/INSTALL.md.
    nixosConfigurations.BigKing = mkHost {
      inherit system;
      specialArgs = {
        inherit
          inputs
          outputs
          pkgs-stable
          ;
        hostConfig = import ./hosts/bigking/hostConfig.nix;
      };
      modules = [
        ./hosts/bigking/default.nix
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            extraSpecialArgs = {
              inherit
                inputs
                outputs
                pkgs-stable
                ;
              hostConfig = import ./hosts/bigking/hostConfig.nix;
            };
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-backup";
            # Same reason as on Whopper: apps rewrite some HM-owned files.
            overwriteBackup = true;
            users = {
              psoldunov = import ./hosts/bigking/home/home.nix;
            };
            sharedModules = [
              sops-nix.homeManagerModules.sops
            ];
          };
        }
      ];
    };

    # Independent household DNS appliance; deliberately omits the full server
    # baseline. Home Manager brings only the shared shell config
    # (hosts/pihome/home.nix). Build its SD image on aarch64-linux.
    nixosConfigurations.PiHome = mkHost {
      system = "aarch64-linux";
      modules = [
        ./hosts/pihome
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            extraSpecialArgs = {
              pkgs-stable = mkPkgsStable "aarch64-linux";
              hostConfig = import ./hosts/pihome/hostConfig.nix;
            };
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-backup";
            users = {
              psoldunov = import ./hosts/pihome/home.nix;
            };
          };
        }
      ];
    };

    checks.${system}.adguard-cli = let
      pkgs = nixpkgs.legacyPackages.${system};
    in
      pkgs.runCommand "adguard-cli-tests" {
        nativeBuildInputs = [pkgs.python3 pkgs.adguardhome pkgs.unbound];
      } ''
        export PYTHONDONTWRITEBYTECODE=1
        export ADGUARDHOME_BIN=${pkgs.adguardhome}
        export UNBOUND_BIN=${pkgs.unbound}
        export AGH_BASE_CONFIG=${pkgs.writeText "pihome-adguard-settings.json" (builtins.toJSON self.nixosConfigurations.PiHome.config.services.adguardhome.settings)}
        python3 -m unittest discover -s ${./packages/adguard-cli} -v
        touch "$out"
      '';

    # Apply on a Mac with `sudo darwin-rebuild switch --flake .#<Host>`, or
    # from another host with `rebuild_system <Host>`.
    darwinConfigurations = {
      BigMac = mkMac "bigmac";
      # MacBook Pro on Wi-Fi.
      MacFlurry = mkMac "macflurry";
    };
  };
}
