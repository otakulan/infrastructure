{ config, pkgs, lib, ... }:

with lib;
{ 
  config = {
    services.grafana = {
      enable = true;
      server = {
        domain = "monitoring.otakulan.net";
        http_port = 3000;
        http_addr = "::1";
      };
    };
  };
}
