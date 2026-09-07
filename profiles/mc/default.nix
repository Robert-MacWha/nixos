{ pkgs, config, ... }:
{
  services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = true;
    dataDir = "/data/documents/minecraft";

    servers.herobrine-mansion-remastered = {
      enable = true;
      package = pkgs.minecraftServers.vanilla-1_11;
      serverProperties = {
        server-port = 25565;
        difficulty = 2;
        gamemode = 0;
        spawn-protection = 0;
        motd = "Herobrine Mansion Remastered";
        enable-command-block = true;
        resource-pack = "https://mediafilez.forgecdn.net/files/2812/983/JSTR_Modded_Universal.zip";
        resource-pack-sha1 = "7a6646a05ef2a9083264a612da621fa5915e0000";
      };
    };
  };
}
