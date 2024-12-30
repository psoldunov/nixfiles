{
  description = "Whopper Configuration ST";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming.url = "github:fufexan/nix-gaming";

    catppuccin = {
      url = "github:catppuccin/nix";
    };

    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager = {
    #   url = "github:nix-community/home-manager";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:Aylur/ags/60180a184cfb32b61a1d871c058b31a3b9b0743d";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ags,
    vscode-server,
    nixpkgs-unstable,
    spicetify-nix,
    nix-gaming,
    nix-flatpak,
    ghostty,
    sops-nix,
    home-manager,
    apple-fonts,
    catppuccin,
    # hyprland,
    ...
  } @ inputs: let
    inherit (self) outputs;

    system = "x86_64-linux";

    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };

    appleFonts = apple-fonts.packages.${system};

    globalSettings = {
      enableHyprland = true;
    };
  in {
    formatter = nixpkgs.pkgs.alejandra;

    nixosConfigurations.Whopper = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          inputs
          outputs
          ghostty
          appleFonts
          globalSettings
          pkgs-unstable
          ;
      };
      modules = [
        ./nixos/configuration.nix
        nix-gaming.nixosModules.pipewireLowLatency
        spicetify-nix.nixosModules.default
        # hyprland.nixosModules.default
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
                pkgs-unstable
                globalSettings
                ;
            };
            useGlobalPkgs = true;
            useUserPackages = true;
            users = {
              psoldunov =
                import ./home-manager/home.nix;
            };
            sharedModules = [
              sops-nix.homeManagerModules.sops
              catppuccin.homeManagerModules.catppuccin
              ags.homeManagerModules.default
              spicetify-nix.homeManagerModules.default
              # hyprland.homeManagerModules.default
            ];
          };
        }
      ];
    };
  };
}
