{ config }:
{
  jellyfin = {
    label = "Jellyfin";
    port = 8096;
    group = "media";
    widget = {
      type = "jellyfin";
      key = "{{HOMEPAGE_FILE_JELLYFIN_API_KEY}}";
    };
  };
  immich = {
    label = "Immich";
    port = config.services.immich.port;
    group = "services";
  };
  gitea = {
    label = "Gitea";
    port = config.services.gitea.settings.server.HTTP_PORT;
    group = "services";
  };
  sonarr = {
    label = "Sonarr";
    port = 8989;
    group = "media";
    widget = {
      type = "sonarr";
      key = "{{HOMEPAGE_FILE_SONARR_API_KEY}}";
    };
  };
  radarr = {
    label = "Radarr";
    port = 7878;
    group = "media";
    widget = {
      type = "radarr";
      key = "{{HOMEPAGE_FILE_RADARR_API_KEY}}";
    };
  };
  prowlarr = {
    label = "Prowlarr";
    port = 9696;
    group = "media";
    widget = {
      type = "prowlarr";
      key = "{{HOMEPAGE_FILE_PROWLARR_API_KEY}}";
    };
  };
}
