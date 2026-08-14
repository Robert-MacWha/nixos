{ lib, ... }:
let
  sataDisks = {
    sata1 = "ata-Samsung_SSD_870_QVO_8TB_S5SSNF0TA02676H";
    sata2 = "ata-Samsung_SSD_870_QVO_8TB_S5SSNF0TA02682R";
    sata3 = "ata-Samsung_SSD_870_QVO_8TB_S5SSNF0TA02686L";
  };

  mkZfsDisk = id: {
    device = "/dev/disk/by-id/${id}";
    type = "disk";
    content = {
      type = "gpt";
      partitions.zfs = {
        size = "100%";
        content = {
          type = "zfs";
          pool = "tank";
        };
      };
    };
  };
in
{
  disko.devices = {
    disk = (lib.mapAttrs (_name: id: mkZfsDisk id) sataDisks) // {
      disk1 = {
        device = lib.mkDefault "/dev/disk/by-id/nvme-Patriot_M.2_P300_128GB_P300EDBB26031903639";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "boot";
              size = "1M";
              type = "EF02";
            };
            esp = {
              name = "ESP";
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            nix = {
              name = "nix";
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/nix";
                mountOptions = [
                  "defaults"
                  "noatime"
                ];
              };
            };
          };
        };
      };
      disk2 = {
        device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_2TB_S6S2NS0TA05862N";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            reth = {
              name = "reth";
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/data/reth";
                mountOptions = [
                  "defaults"
                  "noatime"
                  "nofail"
                ];
              };
            };
          };
        };
      };
    };

    zpool.tank = {
      type = "zpool";
      mode = "raidz1";
      rootFsOptions = {
        compression = "zstd";
        mountpoint = "none";
      };
      options.ashift = "12";

      datasets = {
        "local/root" = {
          type = "zfs_fs";
          mountpoint = "/";
          options.mountpoint = "legacy";
        };
        "data/photos" = {
          type = "zfs_fs";
          mountpoint = "/data/photos";
          options.mountpoint = "legacy";
        };
        "data/media" = {
          type = "zfs_fs";
          mountpoint = "/data/media";
          options.mountpoint = "legacy";
        };
        "data/downloads" = {
          type = "zfs_fs";
          mountpoint = "/data/downloads";
          options.mountpoint = "legacy";
        };
      };
    };
  };
}
