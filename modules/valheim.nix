{ config, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  sops.secrets."valheim_password" = {};

  sops.templates."valheim-env".content = ''
    VALHEIM_PASSWORD="${config.sops.placeholder."valheim_password"}"
  '';

  systemd.services.valheim = {
    description = "Valheim Dedicated Server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    environment = {
      SteamAppId = "892970";
    };

    serviceConfig = {
      Type = "simple";
      User = "reavy";
      WorkingDirectory = "/var/lib/valheim-server";
      EnvironmentFile = config.sops.templates."valheim-env".path;
      
      ExecStartPre = pkgs.writeShellScript "valheim-setup" ''
        ${pkgs.steamcmd}/bin/steamcmd +force_install_dir /var/lib/valheim-server +login anonymous +app_update 896660 validate +quit
        mkdir -p /home/reavy/.steam/sdk64
        ln -sf /var/lib/valheim-server/linux64/steamclient.so /home/reavy/.steam/sdk64/steamclient.so
      '';

      ExecStart = "${pkgs.steam-run}/bin/steam-run /var/lib/valheim-server/valheim_server.x86_64 -nographics -batchmode -name \"SUN\" -port 2456 -world \"Valhallaoderso\" -password \"$VALHEIM_PASSWORD\" -public 1";
      
      Restart = "always";
      RestartSec = "10s";
    };
  };

  services.tailscale.enable = true;
  networking.firewall.interfaces.tailscale0.allowedUDPPorts = [ 2456 2457 ];
}
