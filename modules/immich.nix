{ config, pkgs, ... }:

{
  systemd.tmpfiles.rules = [
    "d /data/immich 0750 immich immich - -"
  ];

  services.immich = {
    enable = true;
    host = "127.0.0.1";
    port = 2283;
    mediaLocation = "/data/immich"; 
  };

  services.caddy.virtualHosts."immich.reavy.dev" = {
    extraConfig = ''
      tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      }
      reverse_proxy localhost:2283
    '';
  };
}
