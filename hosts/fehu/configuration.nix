{ config, pkgs, ... }:
let
  ip = "192.168.2.52";
in
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/services/nixflix.nix
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

  virtualisation.docker.enable = true;

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

  users.groups.homepage-secrets = { };

  sops.secrets = {
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
    "jellyfin_api_key" = {
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
      color = "fuchsia";
    };
    environmentFiles = [
      (pkgs.writeText "homepage-dashboard-env" ''
        HOMEPAGE_FILE_SONARR_API_KEY=${config.sops.secrets."sonarr_api_key".path}
        HOMEPAGE_FILE_RADARR_API_KEY=${config.sops.secrets."radarr_api_key".path}
        HOMEPAGE_FILE_JELLYFIN_API_KEY=${config.sops.secrets."jellyfin_api_key".path}
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
      # {
      #   "machines" = [
      #     {
      #       "Fehu" = {

      #       }
      #     }
      #   ]
      # }
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

  system.stateVersion = "25.05";
}
