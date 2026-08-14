{
  config,
  ...
}:
{
  sops.secrets."jwt_secret" = {
    sopsFile = ../../secrets/ethereum.yaml;
  };

  services.ethereum.lighthouse-beacon.mainnet = {
    enable = true;
    openFirewall = true;
    settings = {
      checkpoint-sync-url = "https://mainnet.checkpoint.sigp.io";
      execution-jwt = config.sops.secrets."jwt_secret".path;
      http-address = "0.0.0.0";

      metrics = true;
      metrics-address = "0.0.0.0";
      metrics-port = 5054;
    };
  };
}
