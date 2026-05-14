{
  description = "BigTasty Configuration Working";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    sops-nix,
    nixpkgs-stable,
    vscode-server,
    home-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;

    system = "x86_64-linux";

    pkgs-stable = import nixpkgs-stable {
      inherit system;
    };
  in {
    formatter = nixpkgs.pkgs.alejandra;

    nixosConfigurations.BigTasty = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs outputs pkgs-stable;
      };
      modules = [
        ./nixos/configuration.nix
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        vscode-server.nixosModules.default
        ({
          config,
          pkgs,
          ...
        }: {
          services.vscode-server.enable = true;
        })
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
            ];
          };
        }
      ];
    };
  };
}
