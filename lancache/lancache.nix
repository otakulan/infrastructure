{ config, pkgs, lib, ... }:

{
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      lancache-monolithic = {
        image = "lancachenet/monolithic:latest";
        autoStart = true;
        ports = [ "${config.env.staticIpv4}:80:80/tcp" "${config.env.staticIpv4}:443:443/tcp" ];
        volumes = [
          "/cache/data:/data/cache:rw"
          "/cache/logs:/data/logs:rw"
        ];
        environment = {
          # 1TB
          CACHE_DISK_SIZE = "1000000m";
          # We recommend 250m of index memory per 1TB of CACHE_DISK_SIZE 
          CACHE_INDEX_SIZE = "250m";
          # Half a year
          CACHE_MAX_AGE = "180d";
          TZ = "America/Toronto";
        };
      };
      lancache-dns = {
        image = "lancachenet/lancache-dns:latest";
        autoStart = true;
        ports = [ "${config.env.staticIpv4}:53:53/tcp" "${config.env.staticIpv4}:53:53/udp" ];
        environment = {
          USE_GENERIC_CACHE = "true";
          LANCACHE_IP = config.env.staticIpv4;
          UPSTREAM_DNS = config.env.dnsServer;
          TZ = "America/Toronto";
        };
      };
    };
  };
}
