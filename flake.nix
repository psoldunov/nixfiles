{
  description = "Whopper Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    zen-browser.url = "github:MarceColl/zen-browser-flake";

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.90.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hyprland.url = "github:hyprwm/Hyprland";

    # hyprland-plugins = {
    #   url = "github:hyprwm/hyprland-plugins";
    #   inputs.hyprland.follows = "hyprland";
    # };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming.url = "github:fufexan/nix-gaming";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

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
    chaotic,
    nixpkgs-stable,
    lix-module,
    nix-ld,
    nix-gaming,
    sops-nix,
    home-manager,
    apple-fonts,
    catppuccin,
    # hyprland,
    # hyprland-plugins,
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
        nix-gaming.nixosModules.platformOptimizations
        # hyprland.nixosModules.default
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        chaotic.nixosModules.default
        catppuccin.nixosModules.catppuccin
        lix-module.nixosModules.default
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
              # hyprland.homeManagerModules.default
              sops-nix.homeManagerModules.sops
              catppuccin.homeManagerModules.catppuccin
              ags.homeManagerModules.default
            ];
          };
        }
      ];
    };
  };
}
