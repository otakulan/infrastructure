{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.samba;
  samba = cfg.package;
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
    # Windows seems to want to do NTP against the DC, noticed
    # this while wiresharking
    services.openntpd.enable = true;

    # https://wiki.samba.org/index.php/Samba_AD_DC_Port_Usage
    networking.firewall.interfaces.eth0.allowedUDPPorts = [ 53 88 123 137 138 389 464 ];
    networking.firewall.interfaces.eth0.allowedTCPPorts = [ 53 88 135 139 389 445 464 636 3268 3269 ];
    # Dynamic RPC Ports
    networking.firewall.allowedTCPPortRanges = [ { from = 49152; to = 65535; } ];

    # https://nixos.wiki/wiki/Samba
    # Disable resolveconf, we're using Samba internal DNS backend
    systemd.services.resolvconf.enable = false;
    environment.etc = {
      "resolv.conf" = {
        text = ''
          search ${config.activeDirectory.domain}
          nameserver ${(builtins.elemAt config.networking.interfaces.eth0.ipv4.addresses 0).address}
        '';
      };
    };

    # Disable default Samba `smbd` service, we will be using the `samba` server binary
    systemd.services.samba-smbd.enable = false;
    systemd.services.samba = {
      description = "Samba Service Daemon";

      requiredBy = [ "samba.target" ];
      partOf = [ "samba.target" ];

      serviceConfig = {
        ExecStart = "${samba}/sbin/samba --foreground --no-process-group";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        LimitNOFILE = 16384;
        PIDFile = "/run/samba.pid";
        Type = "notify";
        NotifyAccess = "all"; # may not do anything...
      };
      unitConfig.RequiresMountsFor = "/var/lib/samba";
      # The nix store path isn't exposed
      restartTriggers = [ "/etc/samba/smb.conf" ];
    };

    services.samba = {
      enable = true;
      openFirewall = true;
      enableNmbd = false;
      enableWinbindd = false;
      configText = ''
        # Global parameters
        [global]
            dns forwarder = ${config.env.dnsServer}
            netbios name = ${config.activeDirectory.netbiosName}
            realm = ${toUpper config.activeDirectory.domain}
            server role = active directory domain controller
            workgroup = ${config.activeDirectory.workgroup}
            idmap_ldb:use rfc2307 = yes
            # Only bind to the production interface, this is to prevent
            # the DNS updater from polluting the DNS with bad records from
            # random network interfaces
            bind interfaces only = yes                                                                                                   
            interfaces = lo eth0

        [netlogon]
            path = /var/lib/samba/sysvol/${config.activeDirectory.domain}/scripts
            read only = No

        [sysvol]
            path = /var/lib/samba/sysvol
            read only = No
      '';
    };

    services.samba = {
      shares = {
        profiles = {
          comment = "Users profiles";
          path = "/samba/profiles";
          browseable = "no";
          "force create mode" = "0600";
          "force directory mode" = "0700";
          "csc policy" = "disables";
          "store dos attributes" = "yes";
          "vfs objects" = "acl_attrs";
        };
        software = {
          path = "/samba/software";
          "read only" = "no";
          "vfs objects" = "acl_attrs";
          "map acl inherit" = "yes";
          "store dos attributes" = "yes";
        };
        "usbmonitor$" = {
          path = "/samba/usbmonitor";
          "read only" = "no";
          "vfs objects" = "acl_attrs";
          "map acl inherit" = "yes";
          "store dos attributes" = "yes";
        };
      };
    };
  };
}
