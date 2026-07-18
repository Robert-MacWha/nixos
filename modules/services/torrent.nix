{ config, pkgs, ... }:
let
  protonvpnConfig = pkgs.runCommand "protonvpn-config" { } ''
    mkdir -p $out
    cp ${./protonvpn/ca-226.protonvpn.udp.ovpn} \
       $out/node-ca-226.protonvpn.udp.ovpn

    cp ${
      pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/haugene/vpn-configs-contrib/main/openvpn/protonvpn/update-port.sh";
        sha256 = "19qf73gjy0gfjy6zy4vsnk8bcgyg5qlnwvs83b3rhy9dqxfsdiqg";
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
    "transmission_env".sopsFile = ../../secrets/nixflix.yaml;
  };

  virtualisation.oci-containers.containers = {
    transmission = {
      image = "haugene/transmission-openvpn:5.4.1";
      ports = [ "9091:9091" ];
      environment = {
        OPENVPN_PROVIDER = "custom";
        OPENVPN_CONFIG = "node-ca-226.protonvpn.udp";
        LOCAL_NETWORK = "192.168.2.0/24";
      };
      volumes = [
        "${protonvpnConfig}:/etc/openvpn/custom"
        "/data/transmission:/config"
        "/data/downloads/transmission:/data"
      ];
      environmentFiles = [ config.sops.secrets."transmission_env".path ]; # OPENVPN_USERNAME / OPENVPN_PASSWORD
      capabilities = {
        # https://haugene.github.io/docker-transmission-openvpn/tips-tricks/#running_this_container_with_podman
        NET_ADMIN = true;
        NET_RAW = true;
        MKNOD = true;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /data/transmission 0755 root root -"
    "d /data/downloads/transmission 0755 root root -"
  ];
}
