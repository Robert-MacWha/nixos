{ config, pkgs, ... }:
{
  networking.firewall = {
    allowedTCPPorts = [
      9091
      9090
    ];
  };

  sops.secrets = {
    "gluetun_env".sopsFile = ../../secrets/nixflix.yaml;
    "transmission_env".sopsFile = ../../secrets/nixflix.yaml;
  };

  virtualisation.oci-containers.containers = {
    gluetun = {
      image = "ghcr.io/qdm12/gluetun:v3.41.1";
      environment = {
        VPN_SERVICE_PROVIDER = "protonvpn";
        VPN_TYPE = "openvpn"; # explicit now, since it's what we're relying on
        VPN_PORT_FORWARDING = "on";
        VPN_PORT_FORWARDING_PROVIDER = "protonvpn";
        UPDATER_PERIOD = "24h";
      };
      environmentFiles = [ config.sops.secrets."gluetun_env".path ]; # OPENVPN_USER / OPENVPN_PASSWORD live here
      volumes = [ "/var/lib/gluetun:/gluetun" ];
      ports = [ "9091:9091" ];
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--device=/dev/net/tun:/dev/net/tun"
        # "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
        "--health-cmd=wget --spider -q http://google.com || exit 1"
        "--health-interval=30s"
        "--health-timeout=10s"
        "--health-retries=3"
      ];
    };

    transmission = {
      image = "lscr.io/linuxserver/transmission:4.1.3-r0-ls352";
      dependsOn = [ "gluetun" ];
      environment = {
        TZ = "America/Toronto";
        USER = "admin";
      };
      environmentFiles = [ config.sops.secrets."transmission_env".path ];
      volumes = [
        "/var/lib/transmission/config:/config"
      ];
      extraOptions = [ "--network=container:gluetun" ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/transmission/config 0755 root root -"
  ];
}
