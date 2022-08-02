{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
  ];
  
  networking.hostName = "builder";

  # sops.defaultSopsFile = ../secrets/builder.yaml;
  system.stateVersion = "22.05";
}
