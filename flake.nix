{
  description = "My NixOS configs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
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

    hackenproof-proxy.url = "path:./modules/hackenproof-proxy";
    hackenproof-proxy.inputs.nixpkgs.follows = "nixpkgs";

    # ethereum.url = "github:nix-community/ethereum.nix";
    # ethereum.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        ./hosts
      ];

      flake.overlays.default = final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          inherit (prev.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        };
      };
    };
}
