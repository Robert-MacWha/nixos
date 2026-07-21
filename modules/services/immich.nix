{ ... }:
{
  users.users.immich.extraGroups = [
    "video"
    "render"
  ];

  services.immich = {
    enable = true;
    openFirewall = true;
    port = 2283;
    host = "0.0.0.0";
    accelerationDevices = null;
    mediaLocation = "/data/photos/immich";
    settings.newVersionCheck.enable = false;
  };
}
