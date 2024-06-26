{
  description = "Whopper Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";

    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    sops-nix,
    home-manager,
    arion,
    apple-fonts,
    catppuccin,
    ...
  } @ inputs: let
    inherit (self) outputs;

    system = "x86_64-linux";
  in {
    formatter = nixpkgs.pkgs.alejandra;

    nixosConfigurations.Whopper = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./nixos/configuration.nix
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        catppuccin.nixosModules.catppuccin
        arion.nixosModules.arion
        {
          fonts.packages = with apple-fonts.packages.${system}; [
            sf-pro
            sf-compact
            sf-mono
            sf-mono-nerd
            sf-arabic
            ny
          ];
        }
        {
          home-manager = {
            extraSpecialArgs = {inherit inputs outputs;};
            useGlobalPkgs = true;
            useUserPackages = true;

            users = {
              psoldunov = import ./home-manager/home.nix;
            };
            sharedModules = [
              sops-nix.homeManagerModules.sops
              catppuccin.homeManagerModules.catppuccin
            ];
          };
        }
      ];
    };
  };
}
