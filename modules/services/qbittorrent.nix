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
  # Need to do this instead of using nixflix's vpn because proton doesn't support
  # fixed-port port forwarding. It instead randomly selects a port for you, which
  # isn't directly compatible with qbittorrent so we use gluetun as a VPN container.
  #
  # NOTE: qbittorrent can't have its password set declaratively. So when first setting up,
  # you will need to check the logs for the temporary password (username = `admin`), and
  # then set a password in the webui.
  #
  # `ssh root@1.2.3.4`
  # `docker logs -t qbittorrent`
  # "The WebUI administrator password was not set. A temporary password is provided for this session:"
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
        PUID = "1000";
        PGID = toString config.users.groups.media.gid;
        TZ = "America/Toronto";
        WEBUI_PORT = "5900";
        QBITTORRENT_INTERFACE = "tun0";
        DOCKER_MODS = "ghcr.io/t-anc/gsp-qbittorent-gluetun-sync-port-mod:main";
        GSP_GTN_API_KEY = "randomapikey";
      };
      volumes = [
        "/data/qbittorrent/config:/config"
        "/data/downloads:/downloads"
      ];
    };
  };
}
