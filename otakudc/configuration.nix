{ config, pkgs, ... }:

{
  imports = [
    ./env.nix
    ./hardware.nix
    ./samba.nix
  ];

  boot.cleanTmpDir = true;
  networking.firewall.allowPing = true;
  networking.firewall.logRefusedConnections = false;
  services.openssh.enable = true;
  networking.hostName = "otakudc";

  users.users.root.shell = pkgs.zsh;

  # sops.defaultSopsFile = ../secrets/otakudc.yaml;
  system.stateVersion = "22.05";
}
