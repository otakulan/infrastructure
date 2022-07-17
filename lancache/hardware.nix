{ modulesPath, ... }:
{
  imports = [
    "${toString modulesPath}/virtualisation/proxmox-lxc.nix"
  ];

  config = {
    proxmoxLXC = {
      manageNetwork = true;
      manageHostName = true;
    };
  };
}
