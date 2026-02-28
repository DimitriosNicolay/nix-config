{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/homepage.nix
    ../../modules/samba.nix
    ../../modules/tailscale.nix
  ];

  users.mutableUsers = false;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "sun";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = true; 
  };

  #secrets
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Define the specific secret
  sops.secrets.reavy-password.neededForUsers = true;

  users.users.reavy = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.reavy-password.path; 
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keyFiles = [
      ../../homelab/keys/reavy.pub
    ];
    packages = with pkgs; [
      git
      neovim
      htop
    ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "24.05"; 
}
