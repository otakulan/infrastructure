{ config, pkgs, lib, ... }:

with lib;
let

in {
  options.activeDirectory = {
    domain = mkOption {
      type = types.str;
    };
    workgroup = mkOption {
      type = types.str;
    };
    netbiosName = mkOption {
      type = types.str;
    };
  };
  
  config = {
    # For Cisco Syslog ingestion
    # (Convert RFC3164 to RFC5424)
    networking.firewall.interfaces.eth0.allowedUDPPorts = [ 514 ];
    networking.firewall.interfaces.eth0.allowedTCPPorts = [ 3100 ];
    services.syslog-ng = {
      enable = true;
      extraConfig = ''
        source s_cisco {
          tcp(port(514) flags(no-parse,store-raw-message));
        };

        parser p_cisco {
          cisco-parser();
        };

        destination d_loki {
          syslog("localhost" transport("tcp") port(1514));
        };

        log {
          source(s_cisco);
          parser(p_cisco);
          destination(d_loki);
        };
      '';
    };

    services.promtail.configuration.scrape_configs = [
      {
        job_name = "cisco_syslog";
        syslog = {
          listen_address = "[::1]:1514";
          idle_timeout = "60s";
          label_structured_data = true;
          labels = {
            job = "cisco_syslog";
          };
        };
        relabel_configs = [
          {
            source_labels = [ "__syslog_message_hostname" ];
            target_label = "host";
          }
        ];
      }
    ];

    services.loki = {
      enable = true;
      configuration = {
        server = {
          http_listen_address = "[::]";
          http_listen_port = 3100;
        };

        auth_enabled = false;

        ingester = {
          lifecycler = {
            address = "[::1]";
            ring = {
              kvstore = {
                store = "inmemory";
              };
              replication_factor = 1;
            };
          };
          chunk_idle_period = "1h";
          max_chunk_age = "1h";
          chunk_target_size = 999999;
          chunk_retain_period = "30s";
          max_transfer_retries = 0;
        };

        schema_config = {
          configs = [{
            from = "2022-06-06";
            store = "boltdb-shipper";
            object_store = "filesystem";
            schema = "v11";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }];
        };

        storage_config = {
          boltdb_shipper = {
            active_index_directory = "/var/lib/loki/boltdb-shipper-active";
            cache_location = "/var/lib/loki/boltdb-shipper-cache";
            cache_ttl = "24h";
            shared_store = "filesystem";
          };

          filesystem = {
            directory = "/var/lib/loki/chunks";
          };
        };

        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
        };

        chunk_store_config = {
          max_look_back_period = "0s";
        };

        table_manager = {
          retention_deletes_enabled = false;
          retention_period = "0s";
        };

        compactor = {
          working_directory = "/var/lib/loki";
          shared_store = "filesystem";
          compactor_ring = {
            kvstore = {
              store = "inmemory";
            };
          };
        };
      };
    };
  };
}
