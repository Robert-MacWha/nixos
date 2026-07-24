{ pkgs, ... }:
{
  containers.tor-relay = {
    ephemeral = true;
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br0";

    bindMounts."/persist/tor-relay/keys" = {
      hostPath = "/var/lib/tor/keys";
      isReadOnly = false;
    };

    config = { pkgs, ... }: {
      services.tor = {
        enable = true;
        relay.enable = true;
        relay.role = "relay";
        settings = {
          Nickname = "Blatancy9964";
          ContactInfo = "snivying@gmail.com";
        };
      };
      services.snowflake-proxy = {
        enable = true;
        capacity = 10;
      };
      system.stateVersion = "25.05";
    };
  };
}
