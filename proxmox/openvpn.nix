{ config, pkgs, ... }:

{
  networking.firewall.allowedUDPPorts = [ 1194 ];
  sops.secrets."openvpn/domainenb" = {};
  services.openvpn.servers = {
    domainenb.config = ''
      dev tun-domainenb
      proto udp
      ifconfig 192.168.2.1 192.168.2.2
      secret ${config.sops.secrets."openvpn/domainenb".path}
      port 1194

      # UDM Pro runs openvpn 2.5.2, we use the default ciphers
      auth-nocache

      keepalive 10 60
      ping-timer-rem
      persist-tun
      persist-key

      # UDM Lan
      route 192.168.0.0 255.255.255.0
      # UDM eth8
      route 192.168.1.0 255.255.255.0
    '';
  };
}
