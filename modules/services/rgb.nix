{ pkgs, ... }:
{
  hardware.i2c.enable = true;

  environment.systemPackages = [ pkgs.openrgb ];
  services.udev.packages = [ pkgs.openrgb ];

  systemd.services.openrgb-off = {
    description = "Turn off RGB via OpenRGB";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.openrgb}/bin/openrgb --mode direct --color 000000";
    };
  };
}
