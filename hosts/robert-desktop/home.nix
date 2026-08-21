{
  config,
  pkgs,
  ...
}:
{
  imports = [ ../../modules/rofi ];

  home = {
    # https://mynixos.com/nixpkgs/package
    packages = with pkgs; [
      # Tools
      bubblewrap
      nixfmt
      sops

      # Dev
      pkgs.unstable.claude-code
      gh
      uv
      nixd

      # Communication
      signal-desktop
      telegram-desktop
      discord
      slack
      element-desktop
      zoom-us

      # General
      orca-slicer
      thunderbird
      mattermost-desktop
      prismlauncher
      jdk17_headless
      usbutils
      rpi-imager
      ledger-live-desktop
      olympus
      kdePackages.kdbusaddons
      obsidian
      firefox
      google-chrome
      libreoffice-qt6-fresh
      proton-vpn
      calibre
      watson
      kdePackages.filelight
      kurve
      cava
      inkscape
      obs-studio
      vlc
      jq
      gnupg
      brotli
      sqlite
    ];

    username = "rmacwha";
    homeDirectory = "/home/rmacwha";

    # Do not ever need to change this
    stateVersion = "25.05";
  };

  sops = {
    age.keyFile = "/home/rmacwha/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
    secrets = {
      ssh-public-key = {
        path = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
        mode = "0644";
      };
      ssh-private-key = {
        path = "${config.home.homeDirectory}/.ssh/id_ed25519";
        mode = "0600";
      };
      crates-io-token = { };
      npm-token = { };
    };
    templates = {
      cargo-credentials = {
        content = ''
          [registry]
          token = "${config.sops.placeholder.crates-io-token}"
        '';
        path = "${config.home.homeDirectory}/.cargo/credentials.toml";
        mode = "0600";
      };
      npmrc = {
        content = ''
          //registry.npmjs.org/:_authToken=${config.sops.placeholder.npm-token}
        '';
        path = "${config.home.homeDirectory}/.npmrc";
        mode = "0600";
      };
    };
  };

  services.gpg-agent = {
    enable = true;
    # pinentry.package = pkgs.pinentry-qt;
  };

  # https://nix-community.github.io/home-manager/options.xhtml
  # or `man home-configuration.nix` for version-specific docs
  programs = {
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      oh-my-zsh = {
        enable = true;
        theme = "eastwood";
        plugins = [ ];
      };
    };

    git = {
      enable = true;
      settings = {
        user.email = "trebor.ahwcam@gmail.com";
        user.name = "Robert-MacWha";
      };
      signing.format = "ssh";
      signing.key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      signing.signByDefault = true;
    };

    vscode = {
      enable = true;
    };
  };
}
