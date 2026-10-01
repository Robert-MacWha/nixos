{
  ...
}:
{
  services.cooklang-server = {
    enable = true;
    port = 3034;
    openFirewall = true;

    repo = "https://github.com/Robert-MacWha/recipes.git";
    ref = "main";
    syncInterval = "*:0/5";
  };
}
