{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ./samba.nix
  ];

  networking.hostName = "otakudc";

  # sops.defaultSopsFile = ../secrets/otakudc.yaml;
  system.stateVersion = "22.05";
}
