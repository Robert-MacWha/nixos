{ config, pkgs, ... }:
{
  sops.secrets."jellyfin_admin_password" = {
    sopsFile = ../../secrets/nixflix.yaml;
  };

  sops.secrets."jellyfin_api_key" = {
    sopsFile = ../../secrets/nixflix.yaml;
  };

  networking.firewall = {
    allowedTCPPorts = [ 8096 ];
  };

  # https://wiki.nixos.org/wiki/Jellyfin
  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  nixflix = {
    enable = true;
    mediaDir = "/data/nixflix/media";
    stateDir = "/data/nixflix/state";

    postgres.enable = true;
    jellyfin = {
      enable = true;
      apiKey = {
        _secret = config.sops.secrets."jellyfin_api_key".path;
      };
      users.admin = {
        policy.isAdministrator = true;
        password = {
          _secret = config.sops.secrets."jellyfin_admin_password".path;
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
          "av1" # UHD 730 (Gen 12/Xe-LP) supports AV1 decoding
        ];
        enableDecodingColorDepth10Hevc = true;
        enableDecodingColorDepth10Vp9 = true;
        enableVppTonemapping = true; # UHD 730 supports Intel's VPP-based tonemapping, better than OpenCL tonemap
        enableIntelLowPowerH264HwEncoder = false; # only enable if you've set up HuC firmware, most people leave off
        enableIntelLowPowerHevcHwEncoder = false;
      };
    };
  };
}
