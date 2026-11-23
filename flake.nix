{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    hermes-agent.url = "github:NousResearch/hermes-agent/v0.23.3";
  };

  outputs = { self, nixpkgs, sops-nix, ... }@inputs: {
    nixosConfigurations.sun = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; }; 
      modules = [
        ./machines/sun/configuration.nix
        sops-nix.nixosModules.sops
      ];
    };
  };
}
