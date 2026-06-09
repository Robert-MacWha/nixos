{
  boot.tmp.cleanOnBoot = true;
  boot.initrd.systemd.enable = true;
  systemd.services.systemd-machine-id-commit.enable = false;

  preservation = {
    enable = true;
    preserveAt."/persistent" = {
      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
      ];

      directories = [
        "/tmp"
        "/var/lib/systemd/timers"
        "/var/lib/nixos"
        "/var/log"
        {
          directory = "/var/lib/hermes";
          user = "hermes";
          group = "hermes";
        }
        {
          directory = "/var/lib/docker";
          user = "root";
          group = "root";
          mode = "0710";
        }
      ];
    };
  };
}
