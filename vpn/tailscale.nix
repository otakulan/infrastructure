{ config, pkgs, lib, ... }:

{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--login-server https://vpn.tdude.co"
      "--advertise-routes=172.16.2.0/24"
    ];
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  sops.secrets.tailscale-authkey = {};
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    restartTriggers = [ config.sops.secrets.tailscale-authkey.path ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ "$status" = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      if [ -f ${config.sops.secrets.tailscale-authkey.path} ]; then
        ${tailscale}/bin/tailscale up ${lib.strings.concatStringsSep " " config.services.tailscale.extraUpFlags} --auth-key "$(cat ${config.sops.secrets.tailscale-authkey.path})"
        exit 0
      fi

      echo "No tailscale authkey found in ${config.sops.secrets.tailscale-authkey.path}" >&2
      exit 1
    '';
  };
}
