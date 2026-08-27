{
  config,
  pkgs,
  lib,
  ...
}:
let
  inferenceBaseUrl = "https://inference.ethereum.foundation/v1";
  defaultModel = "qwen3.8-27b";
in
{
  imports = [
    ../../modules/hackenproof-proxy
    ../../modules/docs-mcp-server
    ../../modules/hermes-profiles
  ];

  users.users.hermes = {
    extraGroups = [
      "docker"
      "gh-cred"
    ];
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
    config.services.hermes-agent.backend.port
  ];

  # Delete the config.yaml file before rebuilding to force regenerate it with new settings.
  system.activationScripts.hermes-agent-setup.text = lib.mkBefore ''
    rm -f /var/lib/hermes/.hermes/config.yaml
  '';
  systemd.services.hermes-agent.path = [ pkgs.docker ];
  # systemd.services.hermes-agent.serviceConfig.TimeoutStopSec = 210;

  services.hermes-agent = {
    enable = true;
    user = "hermes";
    group = "hermes";
    createUser = true;
    stateDir = "/var/lib/hermes";
    environmentFiles = [ config.sops.secrets."hermes-env".path ];
    environment = {
      GH_CONFIG_DIR = "/etc/gh";
      SEARXNG_URL = "http://${config.services.searx.settings.server.bind_address}:${toString config.services.searx.settings.server.port}";
    };
    # https://hermes-agent.nousresearch.com/docs/getting-started/nix-setup/#backend-hermes-serve--hermes-dashboard
    backend = {
      mode = "dashboard";
      host = "0.0.0.0";
      port = 9119;
    };
    extraDependencyGroups = [
      "messaging"
      "hindsight"
    ];
    hermesHomeFiles = {
      "SOUL.md" = ./SOUL.md;
      "hindsight/config.json" = ./hindsight/config.json;
      "skills/solidity-triage/SKILL.md" = ./skills/solidity-triage.md;
    };
    settings = {
      model = {
        provider = "custom";
        default = defaultModel;
        base_url = inferenceBaseUrl;
        api_mode = "chat_completions";
        api_key = "\${ETH_FOUNDATION_API_KEY}";
        reasoning_effort = "low";
      };
      agent = {
        max_turns = 30;
        verbose = false;
      };
      toolsets = [
        "kanban"
      ];
      terminal = {
        backend = "local";
      };
      web = {
        backend = "searxng";
      };
      memory = {
        provider = "hindsight";
        memory_enabled = true;
        user_profile_enabled = true;
      };
      display = {
        compact = false;
        personality = "technical";
      };
      dashboard = {
        theme = "default-large";
        show_token_analytics = true;
      };
      platforms.telegram.extra = {
        ignore_root_dm = true;
        dm_topics = [
          {
            chat_id = 5227927851;
            topics = [
              {
                name = "General";
                thread_id = 113303;
              }
              {
                name = "Random";
                thread_id = 113305;
              }
              {
                name = "Triage";
                thread_id = 113307;
                skill = "solidity-triage";
              }
            ];
          }
        ];
      };
      stt = {
        provider = "openai";
        openai.model = "mistralai/Voxtral-Mini-4B-Realtime-2602";
        openai.base_url = inferenceBaseUrl;
        openai.api_key = "\${VOICE_TOOLS_OPENAI_KEY}";
      };
      onboarding = {
        seen = {
          busy_input_prompt = true;
        };
      };
      skills = {
        disabled = [
          "airtable"
          "ascii-art"
          "ascii-video"
          "weights-and-biases"
          "codex"
          "box"
          "comfyui"
          "competitor-news-monitor"
          "email-inbox-triage"
          "gif-search"
          "humanizer"
          "llama-cpp"
          "manim-video"
          "notion"
          "openhue"
          "p5js"
          "nano-pdf"
          "popular-web-designs"
          "powerpoint"
          "pretext"
          "product-price-monitor"
          "python-debugpy"
          "rust-docker-setup"
          "serving-llms-vllm"
          "songsee"
          "songwriting-and-ai-music"
          "teams-meeting-pipeline"
          "touchdesigner-mcp"
        ];
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
    mcpServers.docs = {
      url = config.services.docs-mcp-server.url;
    };
    addToSystemPackages = true;
    restart = "no";
    restartSec = 5;
  };

  services.hackenproof-proxy = {
    apiKeyFile = config.sops.secrets."hackenproof-api-key".path;
    keyFiles = [ config.sops.secrets."opengpg-private-key".path ];
  };

  services.docs-mcp-server.enable = true;

  virtualisation.oci-containers.containers.hindsight = {
    image = "ghcr.io/vectorize-io/hindsight:latest";
    autoStart = true;
    ports = [
      "127.0.0.1:8888:8888"
      "0.0.0.0:9999:9999"
    ];
    volumes = [ "hindsight-data:/home/hindsight/.pg0" ];
    environmentFiles = [ config.sops.secrets."hermes-env".path ]; # reuse your existing secret
    environment = {
      HINDSIGHT_API_LLM_PROVIDER = "openai";
      HINDSIGHT_API_LLM_MODEL = defaultModel;
      HINDSIGHT_API_LLM_BASE_URL = inferenceBaseUrl;
    };
  };

  services.searx = {
    enable = true;
    settings = {
      use_default_settings.engines.remove = [
        "wikidata"
        "ahmia"
        "torch"
      ];
      server = {
        bind_address = "127.0.0.1";
        port = "8890";
        # Technically insecure, but since searx is only running on this machine and only for hermes
        # and because it's just a local search engine, it's fine.
        secret_key = "e01f8710454165ba1f35ef7707e41be9e189c8087c7cd9e254433ab29c93367a";
      };
      search.formats = [
        "html"
        "json"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "Z /var/lib/hermes/.hermes - hermes hermes -"
    "Z /var/lib/hermes/.hermes/jobs - hermes hermes -"
  ];
}
