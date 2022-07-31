{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ./blackbox.nix
    ./grafana.nix
    ./loki.nix
    ./nginx.nix
    ./prometheus.nix
    ./snmp.nix
  ];

  networking.hostName = "monitoring";

  sops.defaultSopsFile = ../secrets/monitoring.yaml;
  system.stateVersion = "22.05";
}
