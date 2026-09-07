{ self, inputs, ... }:
{
  flake.nixosConfigurations.ansuz = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs self; };
    modules = [
      ./configuration.nix
      inputs.sops-nix.nixosModules.sops
      inputs.disko.nixosModules.disko
      {
        nixpkgs.overlays = [ self.overlays.default ];
      }
    ];
  };
}
