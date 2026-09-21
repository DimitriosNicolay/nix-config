{ config, pkgs, ... }:

{
  sops.secrets."homepage-env" = {};

  services.homepage-dashboard = {
    enable = true;
    allowedHosts = "reavy.dev,localhost";
    openFirewall = true;

    environmentFile = config.sops.secrets."homepage-env".path;

    settings = {
      title = "Sun - Homelab";
      
      theme = "dark";
      color = "slate";
      
      background = {
        image = "https://images.unsplash.com/photo-1599418978625-1fc805bc068d?q=80&w=1770&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D";
        blur = "sm";
        brightness = 50;
      };
      
      layout = {
        "Personal" = {
          style = "row";
          columns = 4;
        };
      };
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
        "Personal" = [
          {
            "Portfolio" = {
              icon = "mdi-web";
              href = "https://dnicolay.de";
              description = "Dimitrios Nicolay";
            };
          }
        ];
      }
      {
        "Infrastructure" = [
          {
            "Sun Server" = {
              icon = "nixos.png";
              href = "https://reavy.dev";
              description = "NixOS Node";
            };
          }
          {
            "Syncthing" = {
              icon = "syncthing.png";
              href = "https://syncthing.reavy.dev";
              description = "File Synchronization";
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
        "Personal Cloud" = [
          {
            "Immich" = {
              icon = "immich.png";
              href = "https://immich.reavy.dev";
              description = "Photo & Video Backup";
              widget = {
                type = "immich";
                url = "http://localhost:2283"; 
                key = "{{HOMEPAGE_VAR_IMMICH_KEY}}";
                version = 2;
                fields = ["photos" "videos" "storage"];
              };
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
