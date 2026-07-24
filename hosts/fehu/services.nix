{ lib, ... }:
{
  options.myHomelab.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          label = lib.mkOption {
            type = lib.types.str;
            description = "Display name shown in the dashboard.";
          };
          port = lib.mkOption {
            type = lib.types.port;
            description = "Port the service listens on.";
          };
          group = lib.mkOption {
            type = lib.types.str;
            description = "Dashboard group/category this service belongs to.";
          };
          widget = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  type = lib.mkOption { type = lib.types.str; };
                  apiKeyEnv = lib.mkOption { type = lib.types.str; };
                };
              }
            );
            default = null;
            description = "Optional homepage-dashboard widget config.";
          };
        };
      }
    );
    default = { };
    description = "Homelab services exposed via Caddy and shown on the dashboard.";
  };

  config.myHomelab.services = {
    jellyfin = {
      label = "Jellyfin";
      port = 8096;
      group = "media";
      widget = {
        type = "jellyfin";
        apiKeyEnv = "JELLYFIN_API_KEY";
      };
    };
    immich = {
      label = "Immich";
      port = 2283; # or config.services.immich.port if you want it dynamic — see note below
      group = "services";
    };
    gitea = {
      label = "Gitea";
      port = 3000; # or config.services.gitea.settings.server.HTTP_PORT
      group = "services";
    };
    sonarr = {
      label = "Sonarr";
      port = 8989;
      group = "media";
      widget = {
        type = "sonarr";
        apiKeyEnv = "SONARR_API_KEY";
      };
    };
    radarr = {
      label = "Radarr";
      port = 7878;
      group = "media";
      widget = {
        type = "radarr";
        apiKeyEnv = "RADARR_API_KEY";
      };
    };
    prowlarr = {
      label = "Prowlarr";
      port = 9696;
      group = "media";
      widget = {
        type = "prowlarr";
        apiKeyEnv = "PROWLARR_API_KEY";
      };
    };
  };
}
