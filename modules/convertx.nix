{ config, pkgs, ... }:

{
  virtualisation.docker.enable = true;

  virtualisation.oci-containers.containers.convertx = {
    image = "ghcr.io/c4illin/convertx:latest";
    ports = [ "3000:3000" ];
    
    volumes = [ "/data/convertx:/app/data" ]; 
    
    environment = {
      AUTO_DELETE_EVERY_N_HOURS = "24";
    };
  };

  services.caddy.virtualHosts."convert.reavy.dev" = {
    extraConfig = ''
      tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      }
      reverse_proxy localhost:3000
    '';
  };
}
