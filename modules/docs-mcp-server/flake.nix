{
  description = "docs-mcp-server: MCP server for fetching, indexing and searching documentation";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.default = pkgs.callPackage ./package.nix { };
      nixosModules.default = import ./module.nix;
    };
}
