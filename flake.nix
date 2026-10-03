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

    nix-flatpak.url = "github:gmodena/nix-flatpak";

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

    nix-gaming.url = "github:fufexan/nix-gaming";

    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
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
  };

  outputs = {
    self,
    nixpkgs,
    zen-browser,
    vscode-server,
    nixpkgs-stable,
    catppuccin,
    nix-gaming,
    nix-flatpak,
    sops-nix,
    home-manager,
    apple-fonts,
    plasma-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;

    system = "x86_64-linux";

    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };

    appleFonts = apple-fonts.packages.${system};

    mkHost = import ./lib/mkHost.nix {inherit nixpkgs;};
  in {
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

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
        nix-flatpak.nixosModules.nix-flatpak
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
              {
                home.packages = [
                  zen-browser.packages."${system}".default
                ];
              }
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
  };
}
