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
