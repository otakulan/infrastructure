{ modulesPath, ... }:
{
  imports = [
    "${toString modulesPath}/virtualisation/proxmox-image.nix"
  ];

  config = {
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/proxmox-image.nix
    proxmox.qemuConf = {
      # When restoring from VMA, check the "unique" box to ensure device mac is randomized.
      net0 = "virtio=00:00:00:00:00:00,bridge=vmbr1,firewall=0";
    };
  };
}
