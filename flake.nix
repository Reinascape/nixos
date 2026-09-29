{
  description = "Reina's Flakes";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    impermanence.url = "github:nix-community/impermanence";

    happ-nix.url = "github:DaHL-gh/happ-nix";    
  };

  outputs = { self, nixpkgs, lanzaboote, chaotic, impermanence, happ-nix, ... }: {
    nixosConfigurations = {
      NixOS = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix
          lanzaboote.nixosModules.lanzaboote
          chaotic.nixosModules.default
          impermanence.nixosModules.impermanence 
          happ-nix.nixosModules.default
        ];
      };
    };
  };
}
