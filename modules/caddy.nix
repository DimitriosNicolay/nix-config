{ config, pkgs, ... }:

{
  sops.secrets.caddy-env = {};

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 80 443 ];

  services.caddy = {
    enable = true;
    
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.3" ];
      hash = "sha256-mmkziFzEMBcdnCWCRiT3UyWPNbINbpd3KUJ0NMW632w="; 
    };

    # Define subdomains
    virtualHosts."reavy.dev" = {
      extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy localhost:8082
      '';
    };
  };
   systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.secrets.caddy-env.path;
}
