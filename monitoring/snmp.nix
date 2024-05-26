{ config, pkgs, lib, ... }:

with lib;
let
  defaultSnmpConfig = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/prometheus/snmp_exporter/44f8732988e726bad3f13d5779f1da7705178642/snmp.yml";
    sha256 = "sha256-WXlpIIurEBnhAQ2kE2vXq28i+0N7v4jHuD/L3NQU+AY=";
  };
in {
  services.prometheus.exporters.snmp = {
    enable = true;
    port = 9116;
    configurationPath = defaultSnmpConfig;
  };
}