{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  python3,
  makeWrapper,
}:

buildNpmPackage rec {
  pname = "docs-mcp-server";
  version = "3.0.1";

  src = fetchFromGitHub {
    owner = "arabold";
    repo = "docs-mcp-server";
    rev = "v${version}";
    hash = "sha256-D1KgLi4tzigCtpjhDnnzBQbrpmXiDqU2Xy/eg4xqgro=";
  };

  npmDepsHash = "sha256-MI6iH72On+eUuJj6qX7LlhAk8pqs6Jus/cQoP/b6A30=";

  nodejs = nodejs_22;

  nativeBuildInputs = [
    python3
    makeWrapper
  ];

  postInstall = ''
    wrapProgram $out/bin/docs-mcp-server \
      --set PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD 1
  '';

  meta = {
    description = "MCP server for fetching, indexing and searching documentation";
    homepage = "https://github.com/arabold/docs-mcp-server";
    license = lib.licenses.mit;
    mainProgram = "docs-mcp-server";
    platforms = lib.platforms.linux;
  };
}
