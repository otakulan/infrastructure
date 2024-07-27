{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ./unifi-controller.nix
  ];
  
  networking.hostName = "unifi-controller";

  # sops.defaultSopsFile = ../secrets/unifi-controller.yaml;
  system.stateVersion = "23.11";
}
