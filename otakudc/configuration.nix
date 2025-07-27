{ config, pkgs, lib, ... }:

{
  imports = [
    ./samba.nix
  ];

  networking.hostName = "otakudc";

  services.cloud-init.enable = lib.mkForce false;

  # sops.defaultSopsFile = ../secrets/otakudc.yaml;
  system.stateVersion = "22.05";
}
