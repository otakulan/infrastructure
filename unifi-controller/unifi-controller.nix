{ config, pkgs, lib, ... }:

{
  networking.firewall.allowedTCPPorts = [ 8443 ]; # missing unifi https port
  services.unifi = {
    enable = true;
    openFirewall = true;
    unifiPackage = pkgs.unifi8;
    mongodbPackage = pkgs.mongodb-6_0;
  };
  services.mongodb = {
    enable = true;
    package = pkgs.mongodb-6_0;
  };
}
