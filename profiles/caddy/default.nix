{
  services,
  domain,
  default ? null,
}:
{ lib, ... }:
let
  proxiedServices = lib.filterAttrs (_: svc: svc ? port) services;

  serviceHosts = lib.mapAttrs' (
    name: svc:
    lib.nameValuePair "http://${name}.${domain}" {
      extraConfig = ''
        reverse_proxy ${svc.ip}:${toString svc.port}
      '';
    }
  ) proxiedServices;

  defaultHost = lib.optionalAttrs (default != null) {
    "http://${domain}" = {
      extraConfig = ''
        reverse_proxy ${default.ip}:${toString default.port}
      '';
    };
  };
in
{
  services.caddy = {
    enable = true;
    openFirewall = true;
    virtualHosts = serviceHosts // defaultHost;
  };
}
