{ config, pkgs, lib, ... }:

with lib;
let
  # https://github.com/prometheus/blackbox_exporter/blob/master/CONFIGURATION.md
  blackboxConfig = {
    modules = {
      https_2xx = {
        prober = "http";
        timeout = "5s";
        http = {
          method = "GET";
          valid_status_codes = [];
          fail_if_not_ssl = true;
        };
      };

      icmp = {
        prober = "icmp";
        timeout = "5s";
      };
    };
  };
in {
  config = {
    services.prometheus.exporters.blackbox = {
      enable = true;
      port = 9115;
      configFile = pkgs.writeText "blackbox.json" (builtins.toJSON blackboxConfig);
    };
  };
}
