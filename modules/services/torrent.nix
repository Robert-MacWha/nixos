{ config, pkgs, ... }:
{
  sops.secrets = {
    "gluetun_env" = {
      sopsFile = ../../secrets/nixflix.yaml;
      # mode = "0440";
      # group = "homepage-secrets";
    };
    "transmission_env" = {
      sopsFile = ../../secrets/nixflix.yaml;
      # mode = "0440";
      # group = "homepage-secrets";
    };
  };

  virtualisation.oci-containers.containers = {
    gluetun = {
      image = "qmcgaw/gluetun:latest";
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--device=/dev/net/tun:/dev/net/tun"
        "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
      ];
      environment = {
        VPN_SERVICE_PROVIDER = "protonvpn";
        VPN_TYPE = "wireguard";
        VPN_PORT_FORWARDING = "on";
        SERVER_COUNTRIES = "Netherlands";
      };
      environmentFiles = [ config.sops.secrets."gluetun_env".path ];
      ports = [
        "9091:9091" # transmission webui, exposed via gluetun's netns
        "51413:51413"
        "51413:51413/udp"
      ];
    };

    transmission = {
      image = "linuxserver/transmission:latest";
      environmentFiles = [ config.sops.secrets."transmission_env".path ];
      volumes = [
        "/var/lib/transmission/config:/config"
        "/data/torrents:/downloads"
      ];
      dependsOn = [ "gluetun" ];
      extraOptions = [ "--network=container:gluetun" ]; # shares gluetun's netns, no separate ports needed
    };
  };
}
