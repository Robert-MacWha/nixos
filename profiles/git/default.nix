{ config, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user.email = "trebor.ahwcam@gmail.com";
      user.name = "Robert-MacWha";
    };
    signing.format = "ssh";
    signing.key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
    signing.signByDefault = true;
  };
}
