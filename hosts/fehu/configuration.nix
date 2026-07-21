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
      ports ? [ ],
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
    # ../../modules/services/dashboard.nix
    # ../../modules/services/immich.nix
    # ../../modules/services/metrics.nix
    # ../../modules/services/nixflix.nix
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
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "enp2s0";
  };

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

  networking.firewall.allowedTCPPorts = [ 3030 ];

  containers.dashboard = mkContainer {
    ip = "10.233.1.1";
    ports = [ 8082 ];
    module = ../../modules/services/dashboard.nix;
  };

  containers.metrics = mkContainer {
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

  containers.immich = mkContainer {
    ip = "10.233.1.3";
    ports = [ 2283 ];
    module = ../../modules/services/immich.nix;
    bindMounts."/data/photos/immich" = {
      hostPath = "/data/photos/immich";
      isReadOnly = false;
    };
    bindMounts."/var/lib/postgresql" = {
      hostPath = "/data/appdata/immich-postgres";
      isReadOnly = false;
    };
  };

  # containers.gitea = mkContainer {
  #   ip = "10.233.1.4";
  #   ports = [ 3030 ];
  #   module = {
  #     services.gitea = {
  #       enable = true;
  #       stateDir = "/data/appdata/gitea";
  #       settings.server.HTTP_ADDR = "0.0.0.0";
  #       settings.server.HTTP_PORT = 3030;
  #     };
  #   };
  # };

  systemd.tmpfiles.rules = mkTmpfilesRules (lib.attrValues config.containers);

  systemd.settings.Manager = {
    DefaultCPUAccounting = true;
    DefaultMemoryAccounting = true;
    DefaultIOAccounting = true;
    DefaultIPAccounting = true;
  };

  system.stateVersion = "25.05";
}
