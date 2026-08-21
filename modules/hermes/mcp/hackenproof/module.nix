{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.hackenproof-proxy;

  wrapped = pkgs.writeShellScript "hackenproof-decrypt-proxy" ''
    exec ${lib.getExe cfg.package} \
      --api-key-file ${lib.escapeShellArg (toString cfg.apiKeyFile)} \
      ${lib.concatMapStringsSep " " (k: "--key-file ${lib.escapeShellArg (toString k)}") cfg.keyFiles} \
      --upstream-url ${lib.escapeShellArg cfg.upstreamUrl}
  '';
in
{
  options.services.hackenproof-proxy = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "The hackenproof-decrypt-proxy package.";
    };

    apiKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing the HackenProof API key. Must be readable by the user hermes runs as.
      '';
    };

    keyFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = ''
        Paths to ASCII-armored, passphrase-less private GPG keys. Must be readable by the user hermes runs as.
      '';
    };

    upstreamUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://mcp.hackenproof.com/mcp";
      description = "The upstream HackenProof MCP endpoint.";
    };

    command = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = ''
        Fully-configured launch command. Assign this to hermes's mcpServers.hackenproof.command.
      '';
    };
  };

  config.services.hackenproof-proxy.command = toString wrapped;
}
