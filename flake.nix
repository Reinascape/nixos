{
  description = "Wenemous's Flakes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    }; 

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  };

  outputs = { self, nixpkgs, lanzaboote, chaotic, ... }: {
    nixosConfigurations = {
      NixOS = nixpkgs.lib.nixosSystem {
        modules = [
          ./configuration.nix
          lanzaboote.nixosModules.lanzaboote
          chaotic.nixosModules.default
        ];
      };
    };
  };
}
