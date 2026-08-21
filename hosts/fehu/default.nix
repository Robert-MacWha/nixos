{ self, inputs, ... }: {
  flake.nixosConfigurations = {
    fehu = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs self; };
      modules = [
        ./configuration.nix
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
        inputs.nixflix.nixosModules.default
      ];
    };
  };
}