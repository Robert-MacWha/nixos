{ config, pkgs, ... }:
let
  ip = "192.168.2.52";
in
{
  users.groups.homepage-secrets = { };

  sops.secrets = {
    "jellyfin_api_key" = {
      sopsFile = ../../secrets/nixflix.yaml;
      mode = "0440";
      group = "homepage-secrets";
    };
    "sonarr_api_key" = {
      sopsFile = ../../secrets/nixflix.yaml;
      mode = "0440";
      group = "homepage-secrets";
    };
    "radarr_api_key" = {
      sopsFile = ../../secrets/nixflix.yaml;
      mode = "0440";
      group = "homepage-secrets";
    };
    "prowlarr_api_key" = {
      sopsFile = ../../secrets/nixflix.yaml;
      mode = "0440";
      group = "homepage-secrets";
    };
    "admin_password" = {
      sopsFile = ../../secrets/nixflix.yaml;
      mode = "0440";
      group = "homepage-secrets";
    };
  };

  systemd.services.homepage-dashboard.serviceConfig.SupplementaryGroups = [
    "homepage-secrets"
  ];

  services.homepage-dashboard = {
    enable = true;
    allowedHosts = "*";
    openFirewall = true;
    settings = {
      title = "Fehu";
      description = "Fehu homeserver dashboard";
      theme = "dark";
      color = "slate";
    };
    environmentFiles = [
      (pkgs.writeText "homepage-dashboard-env" ''
        HOMEPAGE_FILE_SONARR_API_KEY=${config.sops.secrets."sonarr_api_key".path}
        HOMEPAGE_FILE_RADARR_API_KEY=${config.sops.secrets."radarr_api_key".path}
        HOMEPAGE_FILE_JELLYFIN_API_KEY=${config.sops.secrets."jellyfin_api_key".path}
        HOMEPAGE_FILE_PROWLARR_API_KEY=${config.sops.secrets."prowlarr_api_key".path}
        HOMEPAGE_FILE_ADMIN_PASSWORD=${config.sops.secrets."admin_password".path}
      '')
    ];
    services = [
      {
        "infra" = [
          {
            "Router" = {
              href = "http://192.168.2.1";
            };
          }
        ];
      }
      {
        "media" = [
          {
            "Jellyfin" = {
              href = "http://${ip}:8096";
              siteMonitor = "http://${ip}:8096";
              widget = {
                type = "jellyfin";
                url = "http://${ip}:8096";
                key = "{{HOMEPAGE_FILE_JELLYFIN_API_KEY}}";
                enableBlocks = true;
                version = 2;
              };
            };
          }
          {
            "qBittorrent" = {
              href = "http://${ip}:5900";
              siteMonitor = "http://${ip}:5900";
              widget = {
                type = "qbittorrent";
                url = "http://${ip}:5900";
                username = "admin";
                password = "{{HOMEPAGE_FILE_ADMIN_PASSWORD}}";
              };
            };
          }
          {
            "Sonarr" = {
              href = "http://${ip}:8989";
              siteMonitor = "http://${ip}:8989";
              widget = {
                type = "sonarr";
                url = "http://${ip}:8989";
                key = "{{HOMEPAGE_FILE_SONARR_API_KEY}}";
              };
            };
          }
          {
            "Radarr" = {
              href = "http://${ip}:7878";
              siteMonitor = "http://${ip}:7878";
              widget = {
                type = "radarr";
                url = "http://${ip}:7878";
                key = "{{HOMEPAGE_FILE_RADARR_API_KEY}}";
              };
            };
          }
          {
            "Prowlarr" = {
              href = "http://${ip}:9696";
              siteMonitor = "http://${ip}:9696";
              widget = {
                type = "prowlarr";
                url = "http://${ip}:9696";
                key = "{{HOMEPAGE_FILE_PROWLARR_API_KEY}}";
              };
            };
          }
        ];
      }
    ];
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
          uptime = true;
        };
      }
    ];
  };
}
