{ config, ... }: {
  sops.secrets."admin_password" = {
    sopsFile = ../../secrets/nixflix.yaml;
    owner = "grafana";
  };

  sops.secrets."grafana_secret_key" = {
    sopsFile = ../../secrets/nixflix.yaml;
    owner = "grafana";
  };

  services.grafana = {
    enable = true;
    openFirewall = true;
    dataDir = "/data/appdata/grafana";
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
      };
      security = {
        admin_email = "robert@macwha.com";
        admin_user = "admin";
        admin_password = "$__file{${config.sops.secrets."admin_password".path}}";
        secret_key = "$__file{${config.sops.secrets."grafana_secret_key".path}}";
      };
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:8428";
          isDefault = true;
          editable = false;
        }
      ];
    };
  };

  fileSystems."/var/lib/victoriametrics" = {
    device = "/data/appdata/victoriametrics";
    options = [ "bind" ];
  };

  services.victoriametrics = {
    enable = true;
    stateDir = "victoriametrics"; # /var/lib/victoriametrics
    retentionPeriod = "24w";
    prometheusConfig = {
      global.scrape_interval = "10s";
      scrape_configs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
            }
          ];
        }
        {
          job_name = "systemd";
          static_configs = [
            {
              targets = [ "localhost:${toString config.services.prometheus.exporters.systemd.port}" ];
            }
          ];
        }
      ];
    };
  };

  services.prometheus = {
    enable = false;
    exporters.node.enable = true;
    exporters.systemd.enable = true;
  };
}
