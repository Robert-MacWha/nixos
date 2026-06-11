{
  config,
  lib,
  pkgs,
  unstable,
  ...
}:
let
  # orca-slicer = pkgs.callPackage ../../modules/packages/orca-slicer.nix { inherit unstable; };
  # rotki = pkgs.callPackage ../../modules/packages/rotki.nix { };

  rofi-vscode = pkgs.writeShellScriptBin "rofi-vscode" (builtins.readFile ./rofi/vscode.sh);
  rofi-watson = pkgs.writeShellScriptBin "rofi-watson" (builtins.readFile ./rofi/watson.sh);
in
{
  home = {
    # https://mynixos.com/nixpkgs/package
    packages = with pkgs; [
      # Tools
      bubblewrap
      nixfmt
      sops

      # Dev
      unstable.claude-code
      gh
      uv

      # Communication
      signal-desktop
      telegram-desktop
      discord
      slack
      element-desktop
      zoom-us

      # General
      # orca-slicer
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
      inkscape
      obs-studio
      vlc
      jq
      gnupg
      brotli
      sqlite

      (pkgs.runCommand "davinci-resolve-patched" { } ''
        mkdir -p $out/bin $out/share/applications

        ln -s ${davinci-resolve}/bin/davinci-resolve $out/bin/

        substitute ${davinci-resolve}/share/applications/davinci-resolve.desktop \
          $out/share/applications/davinci-resolve.desktop \
          --replace "Exec=davinci-resolve" "Exec=env QT_QPA_PLATFORM=xcb davinci-resolve"

        if [ -d ${davinci-resolve}/share/icons ]; then
          cp -r ${davinci-resolve}/share/icons $out/share/
        fi
      '')

      (pkgs.writeShellScriptBin "rofi-launch" ''
        exec rofi -show combi
      '')
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

    rofi = {
      enable = true;
      theme = "Adapta-Nokto";
      modes = [
        "combi"
        "drun"
        "ssh"
        "vs:${rofi-vscode}/bin/rofi-vscode"
        "tt:${rofi-watson}/bin/rofi-watson"
      ];
      extraConfig = {
        show-icons = true;
        show = "combi";
        combi-modes = "drun,ssh,vs,tt";
        combi-hide-mode-prefix = false;
        click-to-exit = true;
        sort = true;
        # sorting-method = "fzf";
        # matching = "fuzzy";
      };
    };

    # anyrun = {
    #   enable = true;
    #   config = {
    #     closeOnClick = true;
    #     x.fraction = 0.5;
    #     y.fraction = 0.4;
    #     ignoreExclusiveZones = true;
    #     width.absolute = 800;
    #     plugins = [
    #       "${anyrun-plugins.watson}/lib/libanyrun_watson.so"
    #       "${anyrun-plugins.timestamp}/lib/libanyrun_timestamp.so"
    #       "${anyrun-plugins.vscode}/lib/libanyrun_vscode.so"
    #       "${anyrun-plugins.todo}/lib/libanyrun_todo.so"
    #       "libapplications.so"
    #       "librink.so"
    #       "libkidex.so"
    #       "libwebsearch.so"
    #       "libtranslate.so"
    #     ];
    #   };
    #   extraCss = builtins.readFile "${assets}/anyrun.css";
    # };
  };
}
