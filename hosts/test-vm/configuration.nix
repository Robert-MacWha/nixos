{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/services/hermes.nix
  ];

  # Systemd-boot
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  # Grub bootloader
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    efiSupport = false;
  };
  boot.loader.efi.canTouchEfiVariables = false;

  networking.hostName = "test-vm";
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

  sops.age.sshKeyPaths = [ "/persistent/etc/ssh/ssh_host_ed25519_key" ];

  environment.systemPackages = with pkgs; [
    nano
  ];

  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/persistent/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  system.stateVersion = "25.05";
}
