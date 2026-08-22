# To use: copy this directory to hosts/<name>, replace every CHANGEME below,
# add ./<name> to hosts/default.nix, then run nixos-anywhere against the
# target. Once it's up, generate hardware-configuration.nix (eg. via
# `nixos-generate-config --no-filesystems --root /mnt` during the
# nixos-anywhere kexec step) and commit it alongside these files.
{ self, inputs, ... }:
{
  flake.nixosConfigurations.kaunan = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs self; };
    modules = [
      ./configuration.nix
      inputs.sops-nix.nixosModules.sops
      inputs.disko.nixosModules.disko
      inputs.hermes-agent.nixosModules.default
      inputs.hackenproof-proxy.nixosModules.default
      inputs.docs-mcp-server.nixosModules.default
    ];
  };
}
