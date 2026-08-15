{
  config,
  ...
}:
{
  sops.secrets."jwt_secret" = {
    sopsFile = ../../secrets/ethereum.yaml;
  };

  # services.ethereum.reth.mainnet = {
  #   enable = true;
  #   openFirewall = true;

  # };

  services.ethereum.lighthouse-beacon.mainnet = {
    enable = true;
    openFirewall = true;
    settings = {
      execution-endpoint = "http://127.0.0.1:8551";
      execution-jwt = config.sops.secrets."jwt_secret".path;
      checkpoint-sync-url = "https://mainnet.checkpoint.sigp.io";
      http = true;
      http-address = "0.0.0.0";

      metrics = true;
      metrics-address = "0.0.0.0";
      metrics-port = 5054;
    };
  };
}
