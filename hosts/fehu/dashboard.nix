{
  config,
  lib,
  pkgs,
  ...
}:
let
  myServices = import ./services.nix { inherit config; };
  byGroup = lib.groupBy (n: myServices.${n}.group) (builtins.attrNames myServices);

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

  # https://gethomepage.dev/configs/
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
    services = lib.mapAttrsToList (group: names: {
      "${group}" = map (
        name:
        let
          svc = myServices.${name};
          url = if svc ? href then svc.href else "http://${svc.ip}:${toString svc.port}";
        in
        {
          "${svc.label}" =
            (
              if svc ? href then
                {
                  href = svc.href;
                  siteMonitor = svc.href;
                }
              else
                {
                  href = url;
                  siteMonitor = url;
                }
            )
            // lib.optionalAttrs (svc ? widget) {
              widget = svc.widget // {
                url = url;
              };
            };
        }
      ) names;
    }) byGroup;

    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          uptime = true;
          disk = "/";
        };
      }
    ];
  };
}
