{
  boot.tmp.cleanOnBoot = true;
  boot.initrd.systemd.enable = true;

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
        "/var/lib/hermes"
      ];
    };
  };
}
