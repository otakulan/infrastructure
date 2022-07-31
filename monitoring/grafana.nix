{ config, pkgs, lib, ... }:

with lib;
{
  config = {
    services.grafana = {
      enable = true;
      domain = "monitoring.otakulan.net";
      port = 3000;
      addr = "::1";
    };
  };
}
