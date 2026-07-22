{
  boot.tmp.cleanOnBoot = true;

  preservation = {
    enable = true;
    preserveAt."/persistent" = {
      directories = [
        "/var/log"
        "/var/lib"
      ];
    };
  };
}
