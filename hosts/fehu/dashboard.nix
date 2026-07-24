{
  config,
  lib,
  pkgs,
  ...
}:
let
  ip = "192.168.2.52";
  domain = "local";
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
        in
        {
          "${svc.label}" = {
            href = "http://${name}.${domain}";
            siteMonitor = "http://${ip}:${toString svc.port}";
          }
          // lib.optionalAttrs (svc ? widget) {
            widget = svc.widget // {
              url = "http://${ip}:${toString svc.port}";
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
