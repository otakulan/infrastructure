{ config, pkgs, lib, ... }:

with lib;
{
  config = {
    networking.firewall.interfaces.eth0.allowedTCPPorts = [ 80 443 ];
    services.nginx = {
      enable = true;
      virtualHosts = {
        ${config.services.grafana.domain} = {
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.grafana.port}";
            proxyWebsockets = true;
          };
        };
        "prometheus.otakulan.net" = {
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.prometheus.port}";
            proxyWebsockets = true;
          };
        };
        # ${config.services.alertmanager.domain} = {
        #   locations."/" = {
        #     proxyPass = "http://localhost:${toString config.services.alertmanager.port}";
        #     proxyWebsockets = true;
        #   };
        # };
      };
    };
  };
}
