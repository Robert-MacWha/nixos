{ config, pkgs, ... }:
let
  myServices = import ./services.nix { inherit config; };
in
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./dashboard.nix
    (import ../../modules/services/caddy.nix {
      services = myServices;
      domain = "lan";
    })
    ../../modules/services/rgb.nix
    ../../modules/services/nixflix.nix
    ../../modules/services/transmission.nix
    ../../modules/services/metrics.nix
    ../../modules/services/msmtp.nix
    # ../../modules/services/tor.nix
  ];

  # Systemd-boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.kernelParams = [
    "zfs.zfs_arc_max=17179869184"
    "nmi_watchdog=0"
  ];

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

  services.zfs.zed = {
    enableMail = true;
    settings = {
      ZED_EMAIL_ADDR = [ "robert@macwha.com" ];
      ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
      ZED_NOTIFY_INTERVAL_SECS = 3600;
      ZED_NOTIFY_VERBOSE = false;
      ZED_SCRUB_AFTER_RESILVER = true;
    };
  };

  services.smartd = {
    enable = true;
    notifications.mail.enable = true;
    notifications.mail.mailer = "${pkgs.msmtp}/bin/msmtp";
  };

  systemd.settings.Manager = {
    DefaultCPUAccounting = true;
    DefaultMemoryAccounting = true;
    DefaultIOAccounting = true;
    DefaultIPAccounting = true;
  };

  # Power efficiency
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;
    settings = {
      TLP_DEBUG = "disk sysfs pm";

      # --- CPU ---
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "power";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # --- PCIe ASPM ---
      PCIE_ASPM_ON_AC = "powersupersave";
      PCIE_ASPM_ON_BAT = "powersupersave";

      # --- SATA link power management ---
      SATA_LINKPWR_ON_AC = "min_power";
      SATA_LINKPWR_ON_BAT = "min_power";

      # --- Runtime PM for all PCI/SATA devices ---
      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";
      # safety valve: add driver names here if something misbehaves after enabling PM broadly
      # RUNTIME_PM_DRIVER_BLACKLIST = "";

      # --- Audio codec ---
      SOUND_POWER_SAVE_ON_AC = 1;
      SOUND_POWER_SAVE_ON_BAT = 1;
    };
  };

  system.stateVersion = "25.05";
}
