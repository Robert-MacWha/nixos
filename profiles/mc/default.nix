{ pkgs, config, ... }:
let
  minespudcraft-offline-uuid = "3d2a9e1e-1982-3d31-8982-9550271ee669";
in
{
  # Geyser (Bedrock) on the family server
  networking.firewall.allowedUDPPorts = [ 19132 ];

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
        pvp = false;
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

    servers.family = {
      enable = true;
      package = pkgs.fabricServers.fabric-26_2.override { jre_headless = pkgs.jdk25_headless; };
      files."config/Geyser-Fabric/config.yml" = pkgs.writeText "config.yml" ''
        java:
          auth-type: offline
        config-version: 9
      '';
      symlinks = {
        mods = pkgs.linkFarmFromDrvs "mods" (
          builtins.attrValues {
            FabricAPI = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/ewUK83HI/fabric-api-0.161.0%2B26.2.jar";
              sha512 = "2502fa5ade78e9a120b3747bc1a9a2167d6671743bea45bf115d3174c94121aeda87c549446d1a604a9c11fb828de17a551e3514ce42f3e93069dd14bdaee55b";
            };
            Geyser = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/wKkoqHrH/versions/IaIZ9GpY/Geyser-Fabric-2.11.3-b1251.jar";
              sha512 = "2498bd1713b628da9a3316deaf7010c753d612fe2194cf02d6276610eec4541fcb85f7259c3d054d8a4e00aca2edb6053ee63ea930131beadf1ab991ede206a8";
            };
            Lithium = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/f7vZ0VWU/lithium-fabric-0.25.3%2Bmc26.2.jar";
              sha512 = "148b638f3c6229fbaf487120a2344a0af5e411a5aa6533d5db9d75da0a8c0d8304f63eb4cca13f4d03b2c9b4c23d559dd74c1d832422ef8a3087bd005e62a8bd";
            };
          }
        );
      };
      serverProperties = {
        server-port = 25568;
        difficulty = 1;
        gamemode = 0;
        hardcore = false;
        pvp = true;
        motd = "Family Server";
        online-mode = false;
      };
    };
  };
}
