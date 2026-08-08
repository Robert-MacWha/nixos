{ config, pkgs, ... }:
let
  ups-notify = pkgs.writeShellScript "ups-notify" ''
    case "$NOTIFYTYPE" in
      ONBATT)
        systemd-run --unit=ups-delayed-poweroff --on-active=5min -- systemctl poweroff
        ;;
      ONLINE)
        systemctl stop ups-delayed-poweroff.timer 2>/dev/null || true
        ;;
    esac
  '';
in
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

    upsmon.settings = {
      NOTIFYCMD = "${ups-notify}";
      NOTIFYFLAG = [
        [
          "ONLINE"
          "SYSLOG+EXEC"
        ]
        [
          "ONBATT"
          "SYSLOG+EXEC"
        ]
      ];
    };
  };
}
