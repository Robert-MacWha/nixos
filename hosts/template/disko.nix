{
  disko.devices = {
    disk.main = {
      device = "/dev/disk/by-id/CHANGEME";
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
