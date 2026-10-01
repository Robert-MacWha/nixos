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
        inputs.nix-minecraft.nixosModules.minecraft-servers
        inputs.cooklang-server.nixosModules.default
        {
          nixpkgs.overlays = [ self.overlays.default ];
        }
      ];
    };
  };
}
