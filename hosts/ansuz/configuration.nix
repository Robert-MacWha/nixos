{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "ansuz";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.defaultSession = "plasma";
  environment.plasma6.excludePackages = [ pkgs.kdePackages.discover ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  sops.secrets."root_password_hash" = {
    sopsFile = ../../secrets/secrets.yaml;
    neededForUsers = true;
  };

  sops.secrets."ann_password_hash" = {
    sopsFile = ../../secrets/secrets.yaml;
    neededForUsers = true;
  };

  sops.age.sshKeyPaths = [ "/root/.ssh/id_ed25519" ];

  users.mutableUsers = false;
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRvLqaDP5TEXir4skoP4+VzqrbQgjXYPQA2tCF9hc1z rmacwha@robert-desktop"
    ];
    hashedPasswordFile = config.sops.secrets.root_password_hash.path;
  };

  users.users.ann = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.ann_password_hash.path;
  };

  environment.systemPackages = with pkgs; [
    firefox
    chromium
    libreoffice
    vlc
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

  system.stateVersion = "25.05";
}
