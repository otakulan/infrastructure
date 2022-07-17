{ config, pkgs, lib, ... }:

{
  networking.firewall.allowedTCPPorts = [ 25 80 443 993 ];
  networking.firewall.allowedUDPPorts = [ 443 ];

  services.traefik = let
    # hardcoded for now
    combine = a: b: a // b;
    combineAll = list: builtins.foldl' combine { } list;
    backend = address: port: { loadBalancer = { servers = [{ address = "${toString address}:${toString port}"; }]; }; };
    entrypoint = name: port: protocol: {${name} = {address = ":{${toString port}" + "/${protocol}";};};

    mkProxyService = name: def: {
        staticConfigOptions.entryPoints.${name} = {
          address = ":${toString def.port}/${def.protocol}";
        };
       dynamicConfigOptions.${def.protocol} = {
         routers.${name} = ((if def.protocol == "tcp" then {
            rule = "HostSNI(`*`)";
          } else {}) // {
            entrypoints = name;
            service = name;
          });
          services.${name} = backend def.backendIP def.port;
        };
      };

    generateTcpUdpProxyForPort = port: {
      "port-${toString port}-tcp" = {
        port = port;
        protocol = "tcp";
        backendIP = "192.168.0.17";
      };
      "port-${toString port}-port" = {
        port = port;
        protocol = "udp";
        backendIP = "192.168.0.17";
      };
    };

    generateTcpUdpProxyForPorts = ports: map generateTcpUdpProxyForPort ports;

    proxies = combineAll ([{
      smtp = {
        port = 25;
        protocol = "tcp";
        backendIP = "192.168.0.19";
      };
      smtps = {
        port = 465;
        protocol = "tcp";
        backendIP = "192.168.0.19";
      };
      imap = {
        port = 143;
        protocol = "tcp";
        backendIP = "192.168.0.19";
      };
      imaps = {
        port = 993;
        protocol = "tcp";
        backendIP = "192.168.0.19";
      };
      http = {
        port = 80;
        protocol = "tcp";
        backendIP = "192.168.0.16";
      };
      https-tcp = {
        port = 443;
        protocol = "tcp";
        backendIP = "192.168.0.16";
      };
      https-udp = {
        port = 443;
        protocol = "udp";
        backendIP = "192.168.0.16";
      };
      turn-tcp = {
        port = 3478;
        protocol = "tcp";
        backendIP = "192.168.0.17";
      };
      turn-udp = {
        port = 3478;
        protocol = "udp";
        backendIP = "192.168.0.17";
      };
      turns-tcp = {
        port = 5349;
        protocol = "tcp";
        backendIP = "192.168.0.17";
      };
      turns-udp = {
        port = 5349;
        protocol = "udp";
        backendIP = "192.168.0.17";
      };
    }] ++ generateTcpUdpProxyForPorts (builtins.genList (x: x + 49160) 10)); # Generate ports 49160-49169
  in pkgs.lib.mkMerge ([
      {
        enable = true;
      }
    ] ++ (pkgs.lib.mapAttrsToList mkProxyService proxies));
}
