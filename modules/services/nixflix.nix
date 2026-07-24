# https://kiriwalawren.github.io/nixflix/examples/basic-setup/

{
  config,
  inputs,
  ...
}:
let
  fromRepo = inputs.nixflix.lib.jellyfinPlugins.fromRepo;
in
{
  users.groups.media = {
    gid = 3000;
  };

  sops.secrets = {
    "sonarr_api_key".sopsFile = ../../secrets/nixflix.yaml;
    "radarr_api_key".sopsFile = ../../secrets/nixflix.yaml;
    "jellyfin_api_key".sopsFile = ../../secrets/nixflix.yaml;
    "admin_password".sopsFile = ../../secrets/nixflix.yaml;
    "opensubtitles_password".sopsFile = ../../secrets/nixflix.yaml;
    "alpharatio_username".sopsFile = ../../secrets/nixflix.yaml;
    "alpharatio_password".sopsFile = ../../secrets/nixflix.yaml;
    "retrotoon_api_key".sopsFile = ../../secrets/nixflix.yaml;
  };

  networking.firewall = {
    allowedTCPPorts = [
      8096
      9696
      8989
      7878
    ];
  };

  # https://wiki.nixos.org/wiki/Jellyfin
  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  # https://kiriwalawren.github.io/nixflix/getting-started/
  nixflix = {
    enable = true;
    mediaDir = "/data/media";

    postgres.enable = true;

    sonarr = {
      enable = true;
      config = {
        apiKey = {
          _secret = config.sops.secrets."sonarr_api_key".path;
        };
        hostConfig.username = "admin";
        hostConfig.password = {
          _secret = config.sops.secrets."admin_password".path;
        };
      };
    };

    radarr = {
      enable = true;
      config = {
        apiKey = {
          _secret = config.sops.secrets."radarr_api_key".path;
        };
        hostConfig.username = "admin";
        hostConfig.password = {
          _secret = config.sops.secrets."admin_password".path;
        };
      };
    };

    prowlarr = {
      enable = true;
      config = {
        apiKey._secret = config.sops.secrets."prowlarr_api_key".path;
        hostConfig.username = "admin";
        hostConfig.password._secret = config.sops.secrets."admin_password".path;
        indexers = [
          {
            name = "AlphaRatio";
            enable = true;
            username._secret = config.sops.secrets."alpharatio_username".path;
            password._secret = config.sops.secrets."alpharatio_password".path;
          }
          {
            name = "RetroToon";
            enable = true;
            apikey._secret = config.sops.secrets."retrotoon_api_key".path;
          }
          {
            name = "1337x";
            enable = true;

          }
        ];
      };
    };

    flaresolverr.enable = true;

    # https://kiriwalawren.github.io/nixflix/reference/downloadarr/transmission/
    downloadarr.transmission = {
      enable = true;
      host = "127.0.0.1";
      port = 9091;
      username = "admin";
      password = {
        _secret = config.sops.secrets."admin_password".path;
      };
      dependencies = [ "podman-transmission.service" ];
    };

    jellyfin = {
      enable = true;
      apiKey = {
        _secret = config.sops.secrets."jellyfin_api_key".path;
      };

      users.admin = {
        policy.isAdministrator = true;
        password = {
          _secret = config.sops.secrets."admin_password".path;
        };
      };

      users.tv = {
        enableAutoLogin = true;
        password = "";
      };

      system.pluginRepositories = {
        # https://kiriwalawren.github.io/nixflix/examples/jellyfin-plugins/#configuration
        "Intro Skipper" = {
          url = "https://raw.githubusercontent.com/intro-skipper/manifest/main/10.11/manifest.json";
          hash = "sha256:0wh2iszaapyha52z9zxj95562mcph5dj0m0bvkm3q0217r51vq3f";
          enabled = true;
        };
      };

      plugins = {
        # https://kiriwalawren.github.io/nixflix/examples/jellyfin-plugins/#configuration
        "Intro Skipper" = {
          package = fromRepo {
            version = "1.10.11.17";
            hash = "sha256-cfEnLqKeEGpQSth3NPjDnxCkgv2pePfgCXfVIOrYSiQ=";
          };
        };

        # https://kiriwalawren.github.io/nixflix/examples/jellyfin-subtitles/
        "Open Subtitles" = {
          enable = true;
          config = {
            Username = "fiddling9916";
            Password._secret = config.sops.secrets."opensubtitles_password".path;
          };
        };

        # https://kiriwalawren.github.io/nixflix/examples/jellyfin-subtitles/
        "Subtitle Extract" = {
          enable = true;
          config.ExtractionDuringLibraryScan = true;
        };
      };

      # https://kiriwalawren.github.io/nixflix/reference/jellyfin/encoding/
      encoding = {
        enableHardwareEncoding = true;
        hardwareAccelerationType = "qsv";
        qsvDevice = "/dev/dri/renderD128";
        allowHevcEncoding = true;
        allowAv1Encoding = false;
        hardwareDecodingCodecs = [
          "h264"
          "hevc"
          "mpeg2video"
          "vc1"
          "vp8"
          "vp9"
          "av1"
        ];
        enableDecodingColorDepth10Hevc = true;
        enableDecodingColorDepth10Vp9 = true;
        enableVppTonemapping = true; # UHD 730 supports Intel's VPP-based tonemapping, better than OpenCL tonemap
        enableIntelLowPowerH264HwEncoder = true;
        enableIntelLowPowerHevcHwEncoder = true;
      };
    };
  };
}
