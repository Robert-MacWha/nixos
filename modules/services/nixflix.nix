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
    };
  };
}
