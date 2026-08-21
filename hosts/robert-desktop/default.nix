{ self, inputs, ... }: {
  flake.nixosConfigurations = {
    robert-desktop = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs self; };
      modules = [
        ./configuration.nix
        inputs.home-manager.nixosModules.home-manager
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
        inputs.nixflix.nixosModules.default
        {
          nixpkgs.overlays = [ self.overlays.default ];

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
          home-manager.users.rmacwha = import ./home.nix;
        }
      ];
    };
  };
}