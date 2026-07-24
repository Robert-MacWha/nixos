{ config }:
let
  ip = "192.168.2.52";
in
{
  jellyfin = {
    label = "Jellyfin";
    ip = ip;
    port = 8096;
    group = "services";
    widget = {
      type = "jellyfin";
      key = "{{HOMEPAGE_FILE_JELLYFIN_API_KEY}}";
      fields = [
        "movies"
        "series"
      ];
      enableBlocks = false;
      enableNowPlaying = false;
      enableUser = false;
    };
  };
  immich = {
    label = "Immich";
    ip = ip;
    port = config.services.immich.port;
    group = "services";
  };
  gitea = {
    label = "Gitea";
    ip = ip;
    port = config.services.gitea.settings.server.HTTP_PORT;
    group = "services";
  };

  sonarr = {
    label = "Sonarr";
    ip = ip;
    port = 8989;
    group = "media";
    widget = {
      type = "sonarr";
      key = "{{HOMEPAGE_FILE_SONARR_API_KEY}}";
    };
  };
  radarr = {
    label = "Radarr";
    ip = ip;
    port = 7878;
    group = "media";
    widget = {
      type = "radarr";
      key = "{{HOMEPAGE_FILE_RADARR_API_KEY}}";
    };
  };
  transmission = {
    label = "Transmission";
    ip = ip;
    port = 9091;
    group = "media";
    widget = {
      type = "transmission";
      username = "admin";
      password = "{{HOMEPAGE_FILE_ADMIN_PASSWORD}}";
    };
  };
  prowlarr = {
    label = "Prowlarr";
    ip = ip;
    port = 9696;
    group = "media";
    widget = {
      type = "prowlarr";
      key = "{{HOMEPAGE_FILE_PROWLARR_API_KEY}}";
    };
  };

  router = {
    label = "Router";
    group = "infra";
    href = "http://192.168.2.1";
  };
}
