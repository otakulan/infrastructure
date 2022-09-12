{ config, pkgs, lib, ... }:

{
  # Secrets in here will be encrypted next year
  networking.firewall.interfaces.eth0.allowedTCPPorts = [ 4000 ];
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
      };
      lanparty-seating = {
        image = "starcraft66/lanparty-seating:latest";
        autoStart = true;
        ports = [ "${config.env.staticIpv4}:4000:4000/tcp" ];
        environment = {
          SECRET_KEY_BASE = "nah5choh8fohnoap1ien3OoKeehei2ch";
          DATABASE_URL = "ecto://postgres:postgres@localhost/lanpartyseating_prod";
          TZ = "America/Toronto";
        };
      };
    };
  };
}
