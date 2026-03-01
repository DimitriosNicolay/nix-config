{ config, pkgs, ... }:

{
  systemd.tmpfiles.rules = [
    "d /data/syncthing 0750 reavy users - -"
  ];

  services.syncthing = {
    enable = true;
    user = "reavy";
    group = "users";
    dataDir = "/data/syncthing";
    configDir = "/data/syncthing/.config";
    overrideFolders = false;
    overrideDevices = false;

    settings = {
      gui = {
        address = "127.0.0.1:8384";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 21027 ];

  services.caddy.virtualHosts."syncthing.reavy.dev" = {
    extraConfig = ''
      tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      }
      reverse_proxy localhost:8384
    '';
  };
}
