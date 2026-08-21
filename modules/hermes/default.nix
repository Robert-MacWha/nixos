{ config, pkgs, ... }:
let
  apiPort = 6853;
  dashboardPort = 9119;
in
{
  users.users.hermes = {
    extraGroups = [ "docker" ];
  };

  sops.secrets."hermes-env" = {
    owner = "hermes";
    format = "yaml";
    sopsFile = ../../secrets/hermes.yaml;
  };
  sops.secrets."hackenproof-api-key" = {
    owner = "hermes";
    format = "yaml";
    sopsFile = ../../secrets/hermes.yaml;
  };
  sops.secrets."opengpg-private-key" = {
    owner = "hermes";
    format = "yaml";
    sopsFile = ../../secrets/secrets.yaml;
  };

  networking.firewall.allowedTCPPorts = [
    apiPort
    dashboardPort
  ];
  systemd.services.hermes-agent.path = [ pkgs.docker ];
  systemd.services.hermes-agent.serviceConfig.TimeoutStopSec = 210;
  services.hermes-agent = {
    enable = true;
    user = "hermes";
    group = "hermes";
    createUser = true;
    stateDir = "/var/lib/hermes";
    environmentFiles = [ config.sops.secrets."hermes-env".path ];
    environment = {
      API_SERVER_ENABLE = "true";
      API_SERVER_HOST = "0.0.0.0";
      API_SERVER_PORT = toString apiPort;
    };
    extraDependencyGroups = [ "messaging" ];
    settings = {
      model = {
        provider = "custom";
        default = "qwen3.6-27b";
        base_url = "https://inference.ethereum.foundation/v1";
        api_mode = "chat_completions";
        api_key = "\${ETH_FOUNDATION_API_KEY}";
      };
      toolsets = [ "all" ];
      max_turns = 100;
      terminal = {
        backend = "docker";
      };
      web = {
        backend = "ddgs";
      };
      compression = {
        enabled = true;
        threshold = 0.5;
        summary_model = "google/gemma-4-26B-A4B-it";
      };
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
      display = {
        compact = false;
        personality = "technical";
      };
      agent = {
        max_turns = 150;
        verbose = false;
      };
      stt = {
        provider = "openai";
        openai.model = "mistralai/Voxtral-Mini-4B-Realtime-2602";
        openai.base_url = "https://inference.ethereum.foundation/v1";
        openai.api_key = "\${VOICE_TOOLS_OPENAI_KEY}";
      };
    };
    mcpServers.hackenproof = {
      command = config.services.hackenproof-proxy.command;
      tools.exclude = [
        "add_comment"
        "comment_with_attachment"
        "screenshot_and_comment"
        "update_comment"
        "delete_comment"
        "change_state"
        "change_severity"
        "add_labels"
        "remove_labels"
        "triage_report"
        "triage_reports_batch"
        "triage_bulk"
        "set_visibility"
      ];
    };
    mcpServers.github = {
      command = "npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-github"
      ];
      env = {
        GITHUB_PERSONAL_ACCESS_TOKEN = "\${GITHUB_PERSONAL_ACCESS_TOKEN}";
      };
    };
    mcpServers.seal-intel = {
      command = "npx";
      args = [
        "-y"
        "github:zxzinn/opencti-mcp"
      ];
      env = {
        OPENCTI_URL = "\${OPENCTI_URL}";
        OPENCTI_TOKEN = "\${OPENCTI_TOKEN}";
      };
    };

    addToSystemPackages = true;
    restart = "no";
    restartSec = 5;
  };

  services.hackenproof-proxy = {
    apiKeyFile = config.sops.secrets."hackenproof-api-key".path;
    keyFiles = [ config.sops.secrets."opengpg-private-key".path ];
  };

  systemd.tmpfiles.rules = [
    "Z /var/lib/hermes/.hermes - hermes hermes -"
    "Z /var/lib/hermes/.hermes/jobs - hermes hermes -"
    "L+ /var/lib/hermes/.hermes/SOUL.md - - - - ${./SOUL.md}"
  ];
}
