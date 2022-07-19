# Otakuthon LAN Infrastructure As Code

[![Built with Nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

## Development instructions

1. Install [Nix](https://nixos.org/download.html) on your system and enable flake support.
2. If you have `direnv` installed and set up, run `direnv allow`. Otherwise, enter the `devShell` using `nix develop`.
3. Enter your GPG key when asked to decrypt the secrets files.
4. Hack away!

## Create Proxmox API token credentials to provision it via Terraform
1. Access the proxmox web UI.
2. Select the datacenter in the tree on the left, then "API Tokens" under "Permissions".
3. Press "Add", select the user "root@pam" and uncheck "Privilege Separation".
4. Set the token name to "terraform" and press "Add".
5. Take note of the Token ID and Secret as they will be needed in the next step.
6. Select "Pools" under "Permissions" and create a new pool called "k8s".
7. Select "Storage", select "local" in the list of storages and press "edit".
8. Open the "Content" dropdown of the edit directory box and check "Snippets" and press "Save".

## Deploying NixOS LXC containers on Proxmox

1. Run `nix build .#proxmox`
2. Verify that the disk image is created in `result/nixos.tar.xz`
3. Enter the `proxmox/terraform` folder.
4. Select the right terraform workspace (run `terraform workspace list` to list them) using `terraform workspace select <environment>`.
3. Deploy the infrastructure by running `terraform plan -var-file=vars/<environment>.tfvars` and then `terraform apply -var-file=vars/<environment>.tfvars`.
3. Adjust the ip address/hostname of the deployed containers created in the `flake.nix` file in the root of the repo.
4. Create a sops key for the machine using the command `ssh -lroot <hostname> "cat /etc/ssh/ssh_host_rsa_key" | nix-shell -p ssh-to-pgp --run "ssh-to-pgp -o secrets/keys/<hostname>.asc"`. Then, update the `.sops.yaml` file and update `<hostname>`'s key and run `sops updatekeys -y secrets/<hostname>.yaml`.
5. Apply changes to the configuration using `deploy-rs`. For example, to deply `proxmox`, run `deploy .#proxmox`.

## Deploying samba active directory domain controller (otakudc)

1. Adjust `config.env` for the `otakudc` `system` defined in `flake.nix`. Make sure `activeDirectory.{domain,workgroup,netbiosName}`, `dnsServer`, `staticIpv4` and `ipv4DefaultDateway` are set to the expected values (to come).
2. Run `nix build .#otakudc`
3. Verify that the disk image is created in `result/nixos.tar.xz`
4. Adjust the ip address/hostname of the deployed containers created in the `flake.nix` file in the root of the repo (should be the same value as `config.env.staticIpv4` or a dns hostname pointing to that address).
5. In the proxmox web interface, select your storage volume in the left pane and select "CT Templates", then click "Upload".
6. Browse to the aformentioned `nixos-system-x86_64-linux.tar.xz` and upload it to the server.
7. Create a new container using the "Create CT" button at the top right. Follow the wizard and set the resources according to the container's needs. Ignore any networking configuration and leave it as-is. Make sure "Unprivileged Container" is unchecked and "Nesting" is checked.
8. Before starting the container, select it from the left pane, then click "Options", edit "Features" and check "NFS". Then, edit "Console mode" and set it to "/dev/console.
9. Copy an existing samba active directory configuration into `/var/lib/samba` or initialize a new one using `samba-tool domain provision --server-role=dc --use-rfc2307 --dns-backend=SAMBA_INTERNAL --realm=SAMDOM.EXAMPLE.COM --domain=SAMDOM --adminpass=Passw0rd`.
10. REstart samba with `systemctl restart samba`.
11. Apply changes to the configuration using `deploy-rs`. To deply `otakudc`, run `deploy .#otakudc`.

## Administering the active directory domain (on otakudc)

Make sure the only A/AAAA records for `otakulan.net` and `otakudc.otakulan.net` are the expected static IPs of the domain controller. Samba will automatically add records for the current IP addresses it binds to on startup and this can cause unexpected results when starting up the domain controller on a development network with a different IP than the prod one.
```
otakudc# samba-tool dns query localhost otakulan.net otakulan.net A -U tristan
Password for [OTAKULAN\tristan]:
  Name=, Records=2, Children=0
    A: 172.16.2.3 (flags=600000f0, serial=12115, ttl=900)
    A: 172.17.51.242 (flags=600000f0, serial=125336, ttl=900)
[...]
  Name=otakudc, Records=2, Children=0
    A: 172.16.2.3 (flags=f0, serial=12114, ttl=900)
    A: 172.17.51.242 (flags=f0, serial=125333, ttl=900)
otakudc# samba-tool dns query localhost otakulan.net otakulan.net AAAA -U tristan
Password for [OTAKULAN\tristan]:
  Name=, Records=1, Children=0
    AAAA: 2001:0470:b08b:0051:0cca:14ff:fe5a:bc07 (flags=600000f0, serial=125337, ttl=900)
[...]
  Name=otakudc, Records=1, Children=0
    AAAA: 2001:0470:b08b:0051:0cca:14ff:fe5a:bc07 (flags=f0, serial=125334, ttl=900)
```
To remove unwanted entries:
```
otakudc# samba-tool dns delete localhost otakulan.net @ A 172.17.51.242 -U tristan
Password for [OTAKULAN\tristan]:
Record deleted successfully
otakudc# samba-tool dns delete localhost otakulan.net otakudc A 172.17.51.242 -U tristan
Password for [OTAKULAN\tristan]:
Record deleted successfully
otakudc# samba-tool dns delete localhost otakulan.net @ AAAA 2001:0470:b08b:0051:0cca:14ff:fe5a:bc07 -U tristan
Password for [OTAKULAN\tristan]:
Record deleted successfully
otakudc# samba-tool dns delete localhost otakulan.net otakudc AAAA 2001:0470:b08b:0051:0cca:14ff:fe5a:bc07 -U tristan
Password for [OTAKULAN\tristan]:
Record deleted successfully
```

## Deploying the LAN content cache

1. Adjust `config.env` for the `lancache` `system` defined in `flake.nix`. Make sure `dnsServer`, `staticIpv4` and `ipv4DefaultDateway` are set to the expected values (to come).
2. Run `nix build .#lancache`
3. Verify that the disk image is created in `result/nixos-system-x86_64-linux.tar.xz`
4. Adjust the ip address/hostname of the deployed containers created in the `flake.nix` file in the root of the repo (should be the same value as `config.env.staticIpv4` or a dns hostname pointing to that address).
5. In the proxmox web interface, select your storage volume in the left pane and select "CT Templates", then click "Upload".
6. Browse to the aformentioned `nixos-system-x86_64-linux.tar.xz` and upload it to the server.
7. Create a new container using the "Create CT" button at the top right. Follow the wizard and set the resources according to the container's needs. Ignore any networking configuration and leave it as-is. Make sure "Unprivileged Container" and "Nesting" are checked.
8. Before starting the container, select it from the left pane, then click "Options", edit "Features" and check "FUSE". Then, edit "Console mode" and set it to "/dev/console.
9. SSH into the container and create the folders for the cache using `mkdir /cache/{data,logs}`.
10. Apply changes to the configuration using `deploy-rs`. To deply `lancache`, run `deploy .#lancache`.

## Troubleshooting

### First-time deploy
When running `deploy-rs` on a freshly-deployed contianer on proxmox, the first run will fail with this nondescript error:
```
WARNING: /boot being on a different filesystem not supported by init-script-builder.sh
stat: cannot read file system information for '/boot': No such file or directory
no introspection data available for method 'ListUnitsByPatterns' in object '/org/freedesktop/systemd1', and object is not cast to any interface at /nix/store/i9kaw2m3zcaqasin9z714dqiy044ipz9-perl-5.34.1-env/lib/perl5/site_perl/5.34.1/x86_64-linux-thread-multi/Net/DBus/RemoteObject.pm line 467.
⭐ ⚠️ [activate] [WARN] De-activating due to error
```
To fix this, you must scroll up in the log and find the path to the profile being deployed, it looks something like this:
```
🚀 ℹ️ [deploy] [INFO] The following profiles are going to be deployed:
[lancache.system]
user = "root"
ssh_user = "root"
path = "/nix/store/d9640wg9cic4acyis6y1f9whfmyqp1qm-activatable-nixos-system-lancache-22.11.20220712.0906692"
hostname = "172.17.51.249"
ssh_opts = []
```
Then, `ssh` into the container and run `<path>/bin/switch-to-configuration boot` and then run `reboot` to reboot the container. Subsequent deploys will work without a hitch. I have no idea what causes this, I will need to file an upstream bug.

### GPOs fail to apply in windows

If `gpupdate /force` fails to run because of permission issues on the the GPOs, `ssh` into `otakudc` and use the following tools to check and reset the ACLs on the sysvol share.

```
root@otakudc:/var/lib/samba/ > samba-tool ntacl sysvolcheck
[...]
root@otakudc:/var/lib/samba/ > samba-tool ntacl sysvolreset
```

## Deploying configurations to cisco switches (wip/to be tested on real hardware)

Before starting, the switch must be accessible via SSH. If the switch hasn't been configured yet, it must be hooked up via a console cable and configured with a management interface, SSH host keys and an ssh server enabled. This is mostly an excercise left to the reader but something like this should do:

```
ip default-gateway 172.16.2.1
int vlan 30
ip address 172.16.2.xxx 255.255.255.0
conf t
crypto key generate rsa
! Go get a coffee/tea while this runs
line vty 0 4
transport input ssh
login local
password xxxxxxx
exit
ip ssh version 2
```

1. Enable the `cisco-config` `devShell` using `nix develop .#cisco-config`.
2. Enter the `cisco-config` folder.
3. Run `python deploy-configs.py`.