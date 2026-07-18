{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/services/nixflix.nix
    ../../modules/services/dashboard.nix
    ../../modules/services/torrent.nix
  ];

  # Systemd-boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # igpu drivers
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      vpl-gpu-rt
    ];
    # hardware.enableAllFirmware = true; # Required on n100 CPUs
  };

  networking.hostName = "fehu";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  virtualisation.oci-containers.backend = "podman";

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRvLqaDP5TEXir4skoP4+VzqrbQgjXYPQA2tCF9hc1z rmacwha@robert-desktop"
    ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "03:00";
    options = "-d";
  };

  sops.age.sshKeyPaths = [ "/root/.ssh/id_ed25519" ];

  environment.systemPackages = with pkgs; [
    nano
    wget
    unzip
    htop
  ];

  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/root/.ssh/id_ed25519";
        type = "ed25519";
      }
    ];
  };

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
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          isDefault = true;
          editable = false;
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [
    9090
    9798
  ];

  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "10s";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
          }
        ];
      }
      {
        job_name = "speedtest";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.speedtest.port}" ];
          }
        ];
      }
    ];

    exporters.node = {
      enable = true;
    };
  };

  system.stateVersion = "25.05";
}
