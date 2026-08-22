{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.docs-mcp-server;
in
{
  options.services.docs-mcp-server = {
    enable = lib.mkEnableOption "docs-mcp-server, an MCP server for fetching, indexing and searching documentation";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "The docs-mcp-server package.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host to bind the server to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 6280;
      description = "Port to bind the server to.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for the server's port.";
    };

    url = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = ''
        The MCP endpoint URL. Assign this to an MCP client's mcpServers.<name>.url,
        e.g. hermes's services.hermes-agent.mcpServers.docs.url.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.docs-mcp-server.url = "http://${cfg.host}:${toString cfg.port}/mcp";

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    systemd.services.docs-mcp-server = {
      description = "docs-mcp-server: MCP server for fetching, indexing and searching documentation";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
        DOCS_MCP_STORE_PATH = "%S/docs-mcp-server";
      };

      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} --protocol http --host ${cfg.host} --port ${toString cfg.port}";
        DynamicUser = true;
        StateDirectory = "docs-mcp-server";
        StateDirectoryMode = "0750";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
