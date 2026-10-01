{ pkgs, config, ... }:
let
  minespudcraft-offline-uuid = "3d2a9e1e-1982-3d31-8982-9550271ee669";
in
{
  services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = true;
    dataDir = "/data/documents/minecraft";

    servers.herobrine-mansion-remastered = {
      enable = false;
      package = pkgs.minecraftServers.vanilla-1_11;
      serverProperties = {
        server-port = 25565;
        difficulty = 2;
        gamemode = 0;
        spawn-protection = 0;
        motd = "Herobrine Mansion Remastered";
        enable-command-block = true;
        max-players = 10;
        resource-pack = "https://mediafilez.forgecdn.net/files/2812/983/JSTR_Modded_Universal.zip";
        resource-pack-sha1 = "7a6646a05ef2a9083264a612da621fa5915e0000";
        online-mode = false;
      };
      operators = {
        MineSpudCraft = {
          uuid = minespudcraft-offline-uuid;
          level = 4;
        };
      };
    };

    servers.zork = {
      enable = false;
      package = pkgs.minecraftServers.vanilla-1_11;
      serverProperties = {
        server-port = 25566;
        enable-command-block = true;
        difficulty = 0;
        hardcore = false;
        gamemode = 2;
        force-gamemode = true;
        spawn-animals = true;
        spawn-npcs = false;
        view-distance = 10;
        pvp = true;
        spawn-protection = 0;
        max-players = 10;
        motd = "Zork";
        online-mode = false;
      };
      operators = {
        MineSpudCraft = {
          uuid = minespudcraft-offline-uuid;
          level = 4;
        };
      };
    };

    servers.btw = {
      enable = true;
      package = pkgs.legacyFabricServers.legacy-fabric-1_6_4;
      files."BTWConfig.txt" = pkgs.writeText "BTWConfig.txt" ''
        fcEnableHardcoreSpawn=0
        # add any other BTW config options here, one per line, same format as the file itself
      '';
      symlinks = {
        mods = pkgs.linkFarmFromDrvs "mods" (
          builtins.attrValues {
            BetterThanWolves = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/PiC4CKoa/versions/zLnGXEI4/btwce-3.1.1.jar";
              sha512 = "1ebbbf00844844dc23651401aacb0b410c39c9543bab79ce329bfe777e5f328bc69b11e08b88e13eb7ba160ff87fe7733423a12398f5252f75e3b54f25470af9";
            };
          }
        );
      };
      serverProperties = {
        server-port = 25567;
        difficulty = 2;
        hardcore = false;
        gamemode = 0;
        force-gamemode = true;
        view-distance = 12;
        pvp = true;
        spawn-protection = 0;
        max-players = 10;
        motd = "BTW";
        online-mode = false;
      };
      operators = {
        MineSpudCraft = {
          uuid = minespudcraft-offline-uuid;
          level = 4;
        };
      };
    };
  };
}
