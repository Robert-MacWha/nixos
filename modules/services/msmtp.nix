{ config, ... }: {
  sops.secrets."msmtp-password" = {
    sopsFile = ../../secrets/secrets.yaml;
  };

  programs.msmtp = {
    enable = true;
    defaults = {
      aliases = "/etc/msmtprc-aliases";
      port = 587;
      tls = true;
      tls_starttls = true;
    };
    accounts.default = {
      host = "smtp.purelymail.com";
      from = "info@macwha.com";
      user = "info@macwha.com";
      passwordeval = "cat /run/secrets/msmtp-password";
    };
  };
}
