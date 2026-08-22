{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  cmake,
  perl,
  makeWrapper,
  curl,
  openssl,
  zlib,
  rustc,
  cargo,
}:

rustPlatform.buildRustPackage rec {
  pname = "rust-docs-mcp-server";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "Govcraft";
    repo = "rust-docs-mcp-server";
    rev = "v${version}";
    hash = "sha256-jSa4qKZEtZZvYfoRReGDDqH039RH/7Dimo3jmcnnwak=";
  };

  cargoHash = "sha256-iw7dRzwH42HBj2r9y5IHHKLmER7QkyFzLjh7Q+dNMao=";

  nativeBuildInputs = [
    pkg-config
    cmake
    perl
    makeWrapper
  ];

  buildInputs = [
    curl
    openssl
    zlib
  ];

  # Needs `rustc` (via the `cargo` library it embeds) at runtime to build docs
  # for the requested crate.
  postInstall = ''
    wrapProgram $out/bin/rustdocs_mcp_server \
      --prefix PATH : ${lib.makeBinPath [ rustc cargo ]}
  '';

  meta = {
    description = "MCP server providing up-to-date documentation for a single Rust crate via semantic search";
    homepage = "https://github.com/Govcraft/rust-docs-mcp-server";
    license = lib.licenses.mit;
    mainProgram = "rustdocs_mcp_server";
    platforms = lib.platforms.linux;
  };
}
