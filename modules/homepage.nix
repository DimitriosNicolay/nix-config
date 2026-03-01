{ config, pkgs, ... }:

{
  services.homepage-dashboard = {
    enable = true;
    allowedHosts = "reavy.dev,localhost";
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
              href = "https://reavy.dev";
              description = "NixOS Node";
            };
          }
        ];
      }
      {
        "Media Tools" = [
          {
            "ConvertX" = {
              icon = "mdi-autorenew";
              href = "https://convert.reavy.dev";
              description = "Universal File Converter";
            };
          }
        ];
      }
      {
        "Document Management" = [
          {
            "Paperless" = {
              icon = "paperless-ngx.png";
              href = "https://paperless.reavy.dev";
              description = "AI Document Archiving";
              widget = {
                type = "paperlessngx";
                url = "https://paperless.reavy.dev";
                username = "reavy";
                password = config.services.paperless.passwordFile;
              };
            };
          }
        ];
      }
    ];
  };
}
