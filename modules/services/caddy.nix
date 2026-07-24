{ services, domain }:
{ lib, ... }:
let
  proxiedServices = lib.filterAttrs (_: svc: svc ? port) services;
in
{
  services.caddy = {
    enable = true;
    virtualHosts = lib.mapAttrs' (
      name: svc:
      lib.nameValuePair "${name}.${domain}" {
        extraConfig = ''
          reverse_proxy ${svc.ip}:${toString svc.port}
        '';
      }
    ) proxiedServices;
  };
}
