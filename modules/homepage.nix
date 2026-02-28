{ config, pkgs, ... }:

{
  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    settings = {
      title = "Sun - Homelab";
    };
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
      {
        datetime = {
          format = {
            timeStyle = "short";
            dateStyle = "short";
          };
        };
      }
    ];
    services = [
      {
        "Infrastructure" = [
          {
            "Sun Server" = {
              icon = "nixos.png";
              href = "http://192.168.178.32:8082";
              description = "NixOS Node";
            };
          }
        ];
      }
    ];
  };
}
