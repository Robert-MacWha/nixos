{ config, pkgs, ... }:
let
  protonvpnConfig = pkgs.runCommand "protonvpn-config" { } ''
    mkdir -p $out
    cp ${./secrets/protonvpn/node-ca-226.protonvpn.udp.ovpn} \
       $out/node-ca-226.protonvpn.udp.ovpn

    cp ${
      pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/haugene/vpn-configs-contrib/main/openvpn/protonvpn/update-port.sh";
        sha256 = "REPLACE_WITH_ACTUAL_HASH"; # nix-prefetch-url the raw file to get this
      }
    } $out/update-port.sh
    chmod +x $out/update-port.sh
  '';
in
{
  networking.firewall = {
    allowedTCPPorts = [
      9091
    ];
  };

  sops.secrets = {
    "gluetun_env".sopsFile = ../../secrets/nixflix.yaml;
    "transmission_env".sopsFile = ../../secrets/nixflix.yaml;
  };

  virtualisation.oci-containers.containers = {
    transmission = {
      image = "haugene/transmission-openvpn:v5.4.1";
      environment = {
        OPENVPN_PROVIDER = "custom";
        OPENVPN_CONFIG = "node-ca-226.protonvpn.udp";
        LOCAL_NETWORK = "192.168.2.0/24";
      };
      volumes = [
        "${protonvpnConfig}:/etc/openvpn/custom:ro"
      ];
      environmentFiles = [ config.sops.secrets."transmission_env".path ]; # OPENVPN_USER / OPENVPN_PASSWORD
      capabilities = {
        NET_ADMIN = true;
      };
      ports = [ "9091:9091" ];
    };
    # gluetun = {
    #   image = "ghcr.io/qdm12/gluetun:v3.41.1";
    #   environment = {
    #     VPN_SERVICE_PROVIDER = "protonvpn";
    #     VPN_TYPE = "openvpn"; # explicit now, since it's what we're relying on
    #     VPN_PORT_FORWARDING = "on";
    #     VPN_PORT_FORWARDING_PROVIDER = "protonvpn";
    #     UPDATER_PERIOD = "24h";
    #   };
    #   environmentFiles = [ config.sops.secrets."gluetun_env".path ]; # OPENVPN_USER / OPENVPN_PASSWORD live here
    #   volumes = [ "/var/lib/gluetun:/gluetun" ];
    #   ports = [ "9091:9091" ];
    #   extraOptions = [
    #     "--cap-add=NET_ADMIN"
    #     "--device=/dev/net/tun:/dev/net/tun"
    #     # "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
    #     "--health-cmd=wget --spider -q http://google.com || exit 1"
    #     "--health-interval=30s"
    #     "--health-timeout=10s"
    #     "--health-retries=3"
    #   ];
    # };
  };
}
