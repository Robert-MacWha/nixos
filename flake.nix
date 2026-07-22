{
  description = "My NixOS configs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    preservation.url = "github:nix-community/preservation";

    nixflix.url = "github:kiriwalawren/nixflix";
    nixflix.inputs.nixpkgs.follows = "nixpkgs";

    hermes-agent.url = "github:NousResearch/hermes-agent";
    hermes-agent.inputs.nixpkgs.follows = "nixpkgs";

    hackenproof-proxy.url = "path:./modules/services/hermes/mcp/hackenproof";
    hackenproof-proxy.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    inputs:
    let
      system = "x86_64-linux";
      unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations = {
        robert-desktop = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/robert-desktop/configuration.nix
            inputs.home-manager.nixosModules.home-manager
            inputs.sops-nix.nixosModules.sops
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
              home-manager.extraSpecialArgs = { inherit unstable; };
              home-manager.users.rmacwha = import ./hosts/robert-desktop/home.nix;
            }
          ];
        };

        # 192.168.2.50
        perth = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/perth/configuration.nix
            inputs.sops-nix.nixosModules.sops
            inputs.disko.nixosModules.disko
            inputs.preservation.nixosModules.preservation
          ];
        };

        # 192.168.2.51
        test-vm = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/test-vm/configuration.nix
            inputs.sops-nix.nixosModules.sops
            inputs.disko.nixosModules.disko
            inputs.preservation.nixosModules.preservation
            inputs.hermes-agent.nixosModules.default
            inputs.hackenproof-proxy.nixosModules.default
          ];
        };

        # 192.168.2.52
        fehu = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./hosts/fehu/configuration.nix
            inputs.sops-nix.nixosModules.sops
            inputs.disko.nixosModules.disko
            inputs.preservation.nixosModules.preservation
            inputs.nixflix.nixosModules.default
          ];
        };
      };
    };
}
