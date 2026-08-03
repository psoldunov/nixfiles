{
  description = "Whopper Configuration ST";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    catppuccin-vsc.url = "https://flakehub.com/f/catppuccin/vscode/*.tar.gz";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pinned to a pre-python-3.14-default rev. nixos-unstable bumped the default
    # python3 to 3.14 mid-migration (rev f205b55+), breaking patool, catppuccin,
    # catppuccin-gtk and others. Hold nixpkgs here until the 3.14 migration
    # settles upstream, then restore `nixos-unstable`. Other inputs still update.
    nixpkgs.url = "github:nixos/nixpkgs/3e41b24abd260e8f71dbe2f5737d24122f972158";

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    catppuccin = {
      url = "github:catppuccin/nix";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs-stable";
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
            users = {
              psoldunov =
                import ./hosts/whopper/home;
            };
            sharedModules = [
              sops-nix.homeManagerModules.sops
              catppuccin.homeModules.catppuccin
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
