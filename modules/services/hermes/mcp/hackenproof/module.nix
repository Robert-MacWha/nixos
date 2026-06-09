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
      --upstream-url ${lib.escapeShellArg cfg.upstreamUrl} \
      ${
        lib.optionalString (
          cfg.allowedTools != [ ]
        ) "--allowed-tools ${lib.escapeShellArg (lib.concatStringsSep "," cfg.allowedTools)}"
      } \
      ${lib.optionalString (
        cfg.blockedTools != [ ]
      ) "--blocked-tools ${lib.escapeShellArg (lib.concatStringsSep "," cfg.blockedTools)}"}
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
        Path to a file containing the HackenProof API key, typically a
        sops-nix secret path. Must be readable by the user hermes runs as.
      '';
    };

    keyFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = ''
        Paths to ASCII-armored, passphrase-less private GPG keys, typically
        sops-nix secret paths. Must be readable by the user hermes runs as.
      '';
    };

    upstreamUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://mcp.hackenproof.com/mcp";
      description = "The upstream HackenProof MCP endpoint.";
    };

    allowedTools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "get_reports"
        "get_report_details"
        "get_reports_details_batch"
      ];
      description = "If non-empty, ONLY these upstream tools are exposed (default-deny).";
    };

    blockedTools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "update_report"
        "close_report"
      ];
      description = "Upstream tools that are always hidden and rejected.";
    };

    command = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = ''
        Fully-configured launch command. Assign this to hermes's
        mcpServers.hackenproof.command — it needs no further args.
      '';
    };
  };

  config.services.hackenproof-proxy.command = toString wrapped;
}
