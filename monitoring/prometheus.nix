{ config, pkgs, lib, ... }:

with lib;
{
  config = {
    services.prometheus = {
      enable = true;
      port = 9090;
      scrapeConfigs = let
        mkRelabelConfigs = port: [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "localhost:${toString port}";
          }
        ];
        in [
        {
          job_name = "node";
          scrape_interval = "1m";
          static_configs = [{
            targets = [
              # To be changed to DNS aliases
              "172.16.2.2:${toString config.services.prometheus.exporters.node.port}" # lancache
              "172.16.2.3:${toString config.services.prometheus.exporters.node.port}" # otakudc
              # "172.16.2.4:${toString config.services.prometheus.exporters.node.port}" # fogproject
              "172.16.2.6:${toString config.services.prometheus.exporters.node.port}" # builder
              "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" # monitoring
              # "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" 
            ];
          }];
        }
        {
          job_name = "http_probe";
          scrape_interval = "15s";
          params.module = [ "http_2xx" ];
          static_configs = [{
            targets = [
              # To be changed to DNS aliases
              "172.16.2.2:${toString config.services.prometheus.exporters.node.port}" # lancache
              "172.16.2.4:${toString config.services.prometheus.exporters.node.port}" # fogproject
              "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" # monitoring
              # "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" 
            ];
          }];
          relabel_configs = mkRelabelConfigs 9115;
        }
        {
          job_name = "icmp_probe";
          scrape_interval = "10s";
          params.module = [ "icmp" ];
          static_configs = [{
            targets = [
              # To be changed to DNS aliases
              "172.16.2.2" # lancache
              "172.16.2.3" # otakudc
              "172.16.2.4" # fogproject
              "8.8.8.8" # Google
              "1.1.1.1" # Cloudflare
            ];
          }];
          relabel_configs = mkRelabelConfigs 9115;
        }
        {
          job_name = "snmp_network";
          scrape_interval = "1m";
          params.module = [ "if_mib" ];
          static_configs = [{
            targets = [
              # To be changed to DNS aliases
              "172.16.2.30" # OTLAN-D1
              "172.16.2.31" # OTLAN-AXS1
              "172.16.2.32" # OTLAN-AXS2
              "172.16.2.33" # OTLAN-AXS3
              "172.16.2.34" # OTLAN-AXS4
            ];
          }];
          relabel_configs = mkRelabelConfigs 9116;
        }
      ];
    };
  };
}
