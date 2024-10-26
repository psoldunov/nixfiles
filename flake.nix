{
  description = "Whopper Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    zen-browser.url = "github:MarceColl/zen-browser-flake";

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming.url = "github:fufexan/nix-gaming";

    catppuccin = {
      url = "github:catppuccin/nix";
    };

    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:Aylur/ags";
    };
  };

  outputs = {
    self,
    nixpkgs,
    zen-browser,
    ags,
    vscode-server,
    nixpkgs-stable,
    nix-ld,
    nix-gaming,
    nix-flatpak,
    sops-nix,
    home-manager,
    apple-fonts,
    catppuccin,
    hyprland,
    ...
  } @ inputs: let
    inherit (self) outputs;

    system = "x86_64-linux";

    zen-specific = zen-browser.packages."${system}".specific;

    pkgs-stable = import nixpkgs-stable {
      inherit system;
    };

    appleFonts = apple-fonts.packages.${system};
  in {
    formatter = nixpkgs.pkgs.alejandra;

    nixosConfigurations.Whopper = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs outputs appleFonts pkgs-stable;
      };
      modules = [
        ./nixos/configuration.nix
        nix-ld.nixosModules.nix-ld
        nix-gaming.nixosModules.pipewireLowLatency
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
              inherit inputs outputs pkgs-stable zen-specific;
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
              # hyprland.homeManagerModules.default
            ];
          };
        }
      ];
    };
  };
}
