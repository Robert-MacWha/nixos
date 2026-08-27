{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../profiles/hermes
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "kaunan";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  users.groups.gh-cred = { };

  sops.secrets."root_password_hash" = {
    sopsFile = ../../secrets/secrets.yaml;
    owner = "root";
  };
  sops.secrets."github-pat" = {
    sopsFile = ../../secrets/hermes.yaml;
  };
  sops.templates."gh-hosts" = {
    content = ''
      github.com:
          oauth_token: ${config.sops.placeholder."github-pat"}
          user: rmacwha
          git_protocol: https
    '';
    path = "/etc/gh/hosts.yml";
    owner = "root";
    group = "gh-cred";
    mode = "0640";
  };
  sops.templates."gh-config-yml" = {
    content = ''
      version: "1"
    '';
    path = "/etc/gh/config.yml";
    owner = "root";
    group = "gh-cred";
    mode = "0640";
  };
  sops.age.sshKeyPaths = [ "/root/.ssh/id_ed25519" ];

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRvLqaDP5TEXir4skoP4+VzqrbQgjXYPQA2tCF9hc1z rmacwha@robert-desktop"
    ];
    extraGroups = [ "docker" ];
    hashedPasswordFile = config.sops.secrets.root_password_hash.path;
  };

  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    nano
    wget
    unzip
    gh
    jq
    playwright-driver.browsers
    chromium
    uv
  ];

  programs.git = {
    enable = true;
    config = {
      credential.helper = "!gh auth git-credential";
      user.name = "rmacwha-hermes";
      user.email = "trebor.ahwcam@gmail.com";
    };
  };

  environment.variables.GH_CONFIG_DIR = "/etc/gh";

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
