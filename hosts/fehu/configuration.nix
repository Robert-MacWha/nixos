{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  mkContainer =
    {
      ip,
      gateway ? "10.233.0.1",
      module,
      ports,
      bindMounts ? { },
    }:
    let
      allBindMounts = bindMounts // {
        "/root/.ssh/id_ed25519" = {
          hostPath = "/root/.ssh/id_ed25519";
          isReadOnly = true;
        };
      };
    in
    {
      ephemeral = true;
      autoStart = true;
      privateNetwork = true;
      hostAddress = gateway;
      localAddress = ip;
      bindMounts = allBindMounts;
      forwardPorts = map (port: {
        containerPort = port;
        hostPort = port;
        protocol = "tcp";
      }) ports;
      config = {
        imports = [
          module
          inputs.sops-nix.nixosModules.sops
        ];
        sops.age.sshKeyPaths = [ "/root/.ssh/id_ed25519" ];
        system.stateVersion = "25.11";
      };
    };

  # Auto-create host-side dirs for every container's bindMounts
  mkTmpfilesRules =
    containerDefs:
    lib.flatten (
      map (
        c:
        lib.mapAttrsToList (
          _: mount:
          # Only create directories, not the ssh key file (that must already exist)
          lib.optional (!lib.hasSuffix "id_ed25519" mount.hostPath) "d ${mount.hostPath} 0755 root root -"
        ) c.bindMounts
      ) containerDefs
    );
in
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    # ../../modules/services/nixflix.nix
    # ../../modules/services/dashboard.nix
    # ../../modules/services/torrent.nix
  ];

  # Systemd-boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "tank" ];
  boot.zfs.forceImportRoot = false;

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
  networking.hostId = "8425e349";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  virtualisation.oci-containers.backend = "podman";

  sops.secrets."root_password_hash" = {
    sopsFile = ../../secrets/secrets.yaml;
    owner = "root";
  };

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRvLqaDP5TEXir4skoP4+VzqrbQgjXYPQA2tCF9hc1z rmacwha@robert-desktop"
    ];
    hashedPasswordFile = config.sops.secrets.root_password_hash.path;
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

  # containers.testbox = {
  #   privateNetwork = true;
  #   hostAddress = "10.233.1.1";
  #   localAddress = "10.233.1.2";

  #   bindMounts."/shared" = {
  #     hostPath = "/tmp/shared-test";
  #     isReadOnly = false;
  #   };

  #   config = { config, pkgs, ... }: {
  #     system.stateVersion = "25.11";
  #     networking.firewall.enable = false; # simplify for testing
  #     environment.systemPackages = [
  #       pkgs.iproute2
  #       pkgs.util-linux
  #     ];
  #   };
  #   ephemeral = true;
  # };

  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/root/.ssh/id_ed25519";
        type = "ed25519";
      }
    ];
  };

  services.zfs.autoScrub = {
    enable = true;
    interval = "weekly";
    pools = [ "tank" ];
  };

  # sops.secrets."admin_password" = {
  #   sopsFile = ../../secrets/nixflix.yaml;
  #   owner = "grafana";
  # };

  # sops.secrets."grafana_secret_key" = {
  #   sopsFile = ../../secrets/nixflix.yaml;
  #   owner = "grafana";
  # };

  networking.firewall.allowedTCPPorts = [ 3030 ];

  services.gitea = {
    enable = true;
    stateDir = "/data/appdata/gitea";
    settings.server.HTTP_ADDR = "0.0.0.0";
    settings.server.HTTP_PORT = 3030;
  };

  users.users.immich.extraGroups = [
    "video"
    "render"
  ];

  services.immich = {
    enable = true;
    openFirewall = true;
    host = "0.0.0.0";
    accelerationDevices = null;
    mediaLocation = "/data/photos/immich";
    settings.newVersionCheck.enable = false;
  };

  # services.grafana = {
  #   enable = true;
  #   openFirewall = true;
  #   dataDir = "/data/appdata/grafana";
  #   settings = {
  #     server = {
  #       http_addr = "0.0.0.0";
  #       http_port = 3000;
  #     };
  #     security = {
  #       admin_email = "robert@macwha.com";
  #       admin_user = "admin";
  #       admin_password = "$__file{${config.sops.secrets."admin_password".path}}";
  #       secret_key = "$__file{${config.sops.secrets."grafana_secret_key".path}}";
  #     };
  #   };

  #   provision = {
  #     enable = true;
  #     datasources.settings.datasources = [
  #       {
  #         name = "Prometheus";
  #         type = "prometheus";
  #         url = "http://127.0.0.1:8428";
  #         isDefault = true;
  #         editable = false;
  #       }
  #     ];
  #   };
  # };

  # services.victoriametrics = {
  #   enable = true;
  #   stateDir = "/appdata/victoriametrics";
  #   retentionPeriod = "24w";
  #   prometheusConfig = {
  #     global.scrape_interval = "10s";
  #     scrape_configs = [
  #       {
  #         job_name = "node";
  #         static_configs = [
  #           {
  #             targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
  #           }
  #         ];
  #       }
  #       {
  #         job_name = "systemd";
  #         static_configs = [
  #           {
  #             targets = [ "localhost:${toString config.services.prometheus.exporters.systemd.port}" ];
  #           }
  #         ];
  #       }
  #     ];
  #   };
  # };

  containers = {
    metrics = mkContainer {
      ip = "10.233.1.2";
      ports = [ 3000 ];
      module = ../../modules/services/metrics.nix;
      bindMounts."/data/appdata/grafana" = {
        hostPath = "/data/appdata/grafana";
        isReadOnly = false;
      };
      bindMounts."/var/lib/victoriametrics" = {
        hostPath = "/data/appdata/victoriametrics";
        isReadOnly = false;
      };
    };
  };

  systemd.tmpfiles.rules = mkTmpfilesRules (lib.attrValues config.containers);

  systemd.settings.Manager = {
    DefaultCPUAccounting = true;
    DefaultMemoryAccounting = true;
    DefaultIOAccounting = true;
    DefaultIPAccounting = true;
  };

  system.stateVersion = "25.05";
}
