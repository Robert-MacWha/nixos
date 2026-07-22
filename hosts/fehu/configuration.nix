{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/services/dashboard.nix
    ../../modules/services/nixflix.nix
    ../../modules/services/transmission.nix
    ../../modules/services/metrics.nix
  ];

  # Systemd-boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.kernelParams = [ "zfs.zfs_arc_max=17179869184" ];

  swapDevices = [
    {
      device = "/nix/swapfile";
      size = 8192;
    }
  ];

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

  # Ram RGB control
  hardware.i2c.enable = true;

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
    openrgb # Ram RGB control
  ];

  services.udev.packages = [ pkgs.openrgb ];

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

  systemd.settings.Manager = {
    DefaultCPUAccounting = true;
    DefaultMemoryAccounting = true;
    DefaultIOAccounting = true;
    DefaultIPAccounting = true;
  };

  system.stateVersion = "25.05";
}
