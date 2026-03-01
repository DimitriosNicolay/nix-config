{ config, pkgs, ... }:

{
  sops.secrets."paperless-admin-pass" = {
    owner = config.services.paperless.user;
  };

  systemd.tmpfiles.rules = [
    "d /data/paperless 0750 paperless paperless - -"
    "d /data/paperless/data 0750 paperless paperless - -"
    "d /data/paperless/media 0750 paperless paperless - -"
    "d /data/paperless/consume 0770 paperless users - -" 
  ];

  services.paperless = {
    enable = true;
    dataDir = "/data/paperless/data";
    mediaDir = "/data/paperless/media";
    consumptionDir = "/data/paperless/consume";
    
    passwordFile = config.sops.secrets."paperless-admin-pass".path;
    
    settings = {
      PAPERLESS_URL = "https://paperless.reavy.dev";
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_OCR_LANGUAGE = "deu+eng";
    };
  };

  services.caddy.virtualHosts."paperless.reavy.dev" = {
    extraConfig = ''
      tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      }
      reverse_proxy localhost:${toString config.services.paperless.port}
    '';
  };
}
