{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "CHANGEME";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  sops.secrets."root_password_hash" = {
    sopsFile = ../../secrets/secrets.yaml;
    owner = "root";
  };

  sops.age.sshKeyPaths = [ "/root/.ssh/id_ed25519" ];

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRvLqaDP5TEXir4skoP4+VzqrbQgjXYPQA2tCF9hc1z rmacwha@robert-desktop"
    ];
    hashedPasswordFile = config.sops.secrets.root_password_hash.path;
  };

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
