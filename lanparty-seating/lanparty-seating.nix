{ config, pkgs, lib, ... }:

{
  # Secrets in here will be encrypted next year
  networking.firewall.interfaces.eth0.allowedTCPPorts = [ 80 443 ];
  networking.firewall.trustedInterfaces = [ "podman0" ];
  services.nginx = {
    enable = true;
    virtualHosts = {
      "default" = {
        default = true;
        locations."/" = {
          # restrict admin interface to admin VLAN
          extraConfig = ''
            allow 172.16.2.0/24;
            deny all;
          '';
          proxyPass = "http://127.0.0.1:4000/";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        locations."/desktop" = {
          # Desktop client socket wide open
          proxyPass = "http://127.0.0.1:4000/desktop";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
      };
    };
  };
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      postgres = {
        image = "postgres:latest";
        autoStart = true;
        ports = [ "${config.env.staticIpv4}:5432:5432/tcp" ];
        environment = {
          POSTGRES_PASSWORD = "postgres";
          POSTGRES_DB = "lanpartyseating_prod";
          TZ = "America/Toronto";
        };
        volumes = [
          "/var/lib/postgresql/data:/var/lib/postgresql/data"
        ];
      };
      lanparty-seating = {
        image = "ghcr.io/otakulan/lanparty-seating/lanparty-seating:1.0.0";
        autoStart = true;
        ports = [ "127.0.0.1:4000:4000/tcp" ];
        environment = {
          PHX_HOST = "172.16.2.7";
          MIX_ENV = "prod";
          SECRET_KEY_BASE = "nah5choh8fohnoap1ien3OoKeehei2ch";
          DATABASE_URL = "ecto://postgres:postgres@172.16.2.7/lanpartyseating_prod";
          TZ = "America/Toronto";
        };
      };
    };
  };
}
