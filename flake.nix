{
  description = "Whopper Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.90.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ags,
    chaotic,
    nixpkgs-stable,
    lix-module,
    nix-ld,
    nix-gaming,
    sops-nix,
    home-manager,
    arion,
    apple-fonts,
    catppuccin,
    ...
  } @ inputs: let
    inherit (self) outputs;

    system = "x86_64-linux";

    pkgs-stable = import nixpkgs-stable {
      inherit system;
    };
  in {
    formatter = nixpkgs.pkgs.alejandra;

    nixosConfigurations.Whopper = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./nixos/configuration.nix
        nix-ld.nixosModules.nix-ld
        nix-gaming.nixosModules.pipewireLowLatency
        nix-gaming.nixosModules.platformOptimizations
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        chaotic.nixosModules.default
        catppuccin.nixosModules.catppuccin
        lix-module.nixosModules.default
        arion.nixosModules.arion
        {
          services.ollama.package = pkgs-stable.ollama;
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
            extraSpecialArgs = {inherit inputs outputs nixpkgs-stable;};
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
            ];
          };
        }
      ];
    };
  };
}
