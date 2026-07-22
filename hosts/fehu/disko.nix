{ lib, ... }:
let
  sataDisks = {
    sata1 = "ata-Samsung_SSD_870_QVO_8TB_S5SSNF0TA02676H";
    sata2 = "ata-Samsung_SSD_870_QVO_8TB_S5SSNF0TA02681B";
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
            root = {
              name = "root";
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };
    };

    lvm_vg = {
      pool = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [
                "defaults"
              ];
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
        "system/persist" = {
          type = "zfs_fs";
          mountpoint = "/persistent";
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
