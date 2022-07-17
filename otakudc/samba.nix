{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.samba;
  samba = cfg.package;
  nssModulesPath = config.system.nssModules.path;
in {
  # https://nixos.wiki/wiki/Samba
  # Disable resolveconf, we're using Samba internal DNS backend
  systemd.services.resolvconf.enable = false;
  environment.etc = {
    "resolv.conf" = {
      text = ''
        search ${config.env.activeDirectory.domain}
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
  };

  services.samba = {
    enable = true;
    enableNmbd = false;
    enableWinbindd = false;
    configText = ''
      # Global parameters
      [global]
          dns forwarder = ${config.env.dnsServer}
          netbios name = ${config.env.activeDirectory.netbiosName}
          realm = ${toUpper config.env.activeDirectory.domain}
          server role = active directory domain controller
          workgroup = ${config.env.activeDirectory.workgroup}
          idmap_ldb:use rfc2307 = yes

      [netlogon]
          path = /var/lib/samba/sysvol/${config.env.activeDirectory.domain}/scripts
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
}
