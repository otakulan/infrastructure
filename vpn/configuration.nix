{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ./hardware.nix
    ./tailscale.nix
  ];
  
  networking.hostName = "vpn";

  sops.defaultSopsFile = ../secrets/vpn.yaml;
  system.stateVersion = "23.11";
}
