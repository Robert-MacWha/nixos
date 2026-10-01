{ self, inputs, ... }:
let
  system = "x86_64-linux";
in
{
  flake.nixosConfigurations = {
    robert-desktop = inputs.nixpkgs.lib.nixosSystem {
      inherit system;
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
          home-manager.extraSpecialArgs = {
            anyrun-plugins = inputs.anyrun-plugins.packages.${system};
          };
        }
      ];
    };
  };
}
