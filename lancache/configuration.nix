{ config, pkgs, ... }:

{
  imports = [
    ./env.nix
    ./hardware.nix
    ./lancache.nix
  ];
  
  networking.hostName = "lancache";

  # sops.defaultSopsFile = ../secrets/otakudc.yaml;
  system.stateVersion = "22.05";
}
