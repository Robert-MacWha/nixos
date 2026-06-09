{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
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

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRvLqaDP5TEXir4skoP4+VzqrbQgjXYPQA2tCF9hc1z rmacwha@robert-desktop"
    ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  sops = {
    age.sshKeyPaths = [ "/persistent/etc/ssh/ssh_host_ed25519_key" ];
    secrets."hermes-env" = {
      format = "yaml";
      sopsFile = ../../secrets/hermes.yaml;
    };
  };

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

  services.hermes-agent = {
    enable = true;
    user = "hermes";
    group = "hermes";
    createUser = true;
    stateDir = "/var/lib/hermes";
    workingDirectory = "/var/lib/hermes-working";
    environmentFiles = [ config.sops.secrets."hermes-env".path ];
    extraDependencyGroups = [ "messaging" ];
    settings = {
      model = {
        provider = "custom";
        default = "gemini/gemini-3.1-pro-preview";
        base_url = "https://inference.ethereum.foundation/v1";
        api_mode = "chat_completions";
        api_key = "\${ETH_FOUNDATION_API_KEY}";
      };
      toolsets = [ "all" ];
      max_turns = 100;
      terminal = {
        backend = "local";
        cwd = ".";
        timeout = 180;
      };
      web = {
        backend = "ddgs";
      };
      compression = {
        enabled = true;
        threshold = 0.5;
        summary_model = "google/gemma-4-26B-A4B-it";
      };
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
      display = {
        compact = false;
        personality = "kawaii";
      };
      agent = {
        max_turns = 150;
        verbose = false;
      };
      # documents = {
      #   "USER.md" = ./documents/USER.md;
      # };
    };

    addToSystemPackages = true;
    restart = "always";
    restartSec = 5;
  };

  system.stateVersion = "25.05";
}
