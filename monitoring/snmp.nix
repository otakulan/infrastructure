{ config, pkgs, lib, ... }:

with lib;
let
  defaultSnmpConfig = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/prometheus/snmp_exporter/969516950f086a1d86968d7a89b976a092c8191f/snmp.yml";
    sha256 = "sha256-9YPeINfamINpZKtx+dcJc99rBe9cJW0l8SrIM3GYlZ4=";
  };
in {
  services.prometheus.exporters.snmp = {
    enable = true;
    port = 9116;
    configurationPath = defaultSnmpConfig;
  };
}