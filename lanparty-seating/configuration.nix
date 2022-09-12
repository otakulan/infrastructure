{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ./lanparty-seating.nix
  ];
  
  networking.hostName = "lanparty-seating";

  # sops.defaultSopsFile = ../secrets/lanparty-seating.yaml;
  system.stateVersion = "22.05";
}
