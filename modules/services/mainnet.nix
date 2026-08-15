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
  #   settings = {
  #     full = true;
  #     http = true;
  #     "http.addr" = "0.0.0.0";
  #     "http.api" = [
  #       "net"
  #       "web3"
  #       "eth"
  #     ];
  #     "authrpc.jwtsecret" = config.sops.secrets."jwt_secret".path;
  #     metrics = "0.0.0.0:6060";
  #   };
  # };

  services.ethereum.lighthouse-beacon.mainnet = {
    enable = true;
    openFirewall = true;
    settings = {
      network = "mainnet";
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

  systemd.services.lighthouse-beacon-mainnet.serviceConfig.BindPaths = [
    "/data/reth/lighthouse-mainnet:/var/lib/lighthouse-mainnet"
  ];
}
