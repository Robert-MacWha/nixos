{
  services,
  domain,
  default ? null,
}:
{
  lib,
  pkgs,
  config,
  ...
}:
let
  proxiedServices = lib.filterAttrs (_: svc: svc ? port) services;

  hostConfig = svc: {
    extraConfig = ''
      reverse_proxy ${svc.ip}:${toString svc.port}
    '';
  };

  serviceHosts = lib.listToAttrs (
    lib.concatMap (
      name:
      let
        svc = proxiedServices.${name};
        names = [ name ] ++ (svc.aliases or [ ]);
      in
      map (n: lib.nameValuePair "${n}.${domain}" (hostConfig svc)) names
    ) (builtins.attrNames proxiedServices)
  );

  defaultHost = lib.optionalAttrs (default != null) {
    "${domain}" = hostConfig default;
  };
in
{
  sops.secrets."cloudflare_api_token".sopsFile = ../../secrets/caddy.yaml;

  sops.templates."caddy.env" = {
    content = ''
      CLOUDFLARE_API_TOKEN=${config.sops.placeholder."cloudflare_api_token"}
    '';
    owner = "caddy";
  };

  services.caddy = {
    enable = true;
    openFirewall = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
      hash = "sha256-PWadA5qr/gR2qDcT8l8u1Xku7LM2HIfWTLOkzezCYy0=";
    };
    environmentFile = config.sops.templates."caddy.env".path;
    globalConfig = ''
      acme_dns cloudflare {$CLOUDFLARE_API_TOKEN}
    '';
    virtualHosts = serviceHosts // defaultHost;
  };
}
