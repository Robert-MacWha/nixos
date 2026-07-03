{ config, pkgs, ... }:
{
  sops.secrets = {
    "gluetun_env".sopsFile = ../../secrets/nixflix.yaml;
  };

  networking.firewall = {
    allowedTCPPorts = [
      5900
    ];
  };

  # https://github.com/qdm12/gluetun-wiki/blob/main/setup/providers/protonvpn.md
  virtualisation.oci-containers.containers = {
    gluetun = {
      image = "ghcr.io/qdm12/gluetun:v3";
      autoStart = true;
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--device=/dev/net/tun:/dev/net/tun"
        "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
      ];
      environment = {
        VPN_SERVICE_PROVIDER = "protonvpn";
        VPN_PORT_FORWARDING = "on";
        VPN_PORT_FORWARDING_PROVIDER = "protonvpn";
        QBT_WEBUI_ENABLED = "true";
        UPDATER_PERIOD = "24h";
      };
      environmentFiles = [ config.sops.secrets."gluetun_env".path ]; # OPENVPN_USER / OPENVPN_PASSWORD
      volumes = [ "/var/lib/gluetun:/gluetun" ];
      ports = [ "5900:5900" ];
    };

    qbittorrent = {
      image = "lscr.io/linuxserver/qbittorrent:latest";
      autoStart = true;
      dependsOn = [ "gluetun" ];
      extraOptions = [ "--network=container:gluetun" ];
      environment = {
        PUID = "0";
        PGID = "0";
        TZ = "America/Toronto";
        WEBUI_PORT = "5900";
        QBITTORRENT_INTERFACE = "tun0";
        DOCKER_MODS = "ghcr.io/t-anc/gsp-qbittorent-gluetun-sync-port-mod:main";
        GSP_GTN_API_KEY = "randomapikey";
      };
      volumes = [
        "/var/lib/qbittorrent:/config"
        "/mnt/media:/mnt/media"
      ];
    };
  };
}
