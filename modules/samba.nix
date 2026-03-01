{ config, pkgs, ... }:

{
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "Sun-NAS";
        "netbios name" = "sun";
        "security" = "user";
        "hosts allow" = "192.168.178. 127.0.0.1 100.";
        "map to guest" = "bad user";
      };
      "public" = {
        "path" = "/data";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "reavy";
      };
      "Scan" = {
        "path" = "/data/paperless/consume";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0664";
        "directory mask" = "0775";
        "force user" = "paperless";
        "force group" = "users";
      };
    };
  };

  services.samba-wsdd.enable = true;
}
