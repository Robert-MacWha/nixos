{
  disko.devices = {
    disk.main = {
      device = "/dev/disk/by-id/nvme-PC711_NVMe_SK_hynix_512GB____CNB7N623510107P4K";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "500M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
