{ config, ... }:
{
  sops.secrets."root_password" = {
    sopsFile = ../../secrets/secrets.yaml;
  };

  power.ups = {
    enable = true;
    mode = "netclient";

    upsmon.monitor."myups" = {
      system = "myups@192.168.2.163:3493";
      user = "nut";
      passwordFile = config.sops.secrets.root_password.path;
      type = "secondary";
      powerValue = 1;
    };
  };
}
