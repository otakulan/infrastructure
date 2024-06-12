{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    flake-parts.url = "github:hercules-ci/flake-parts";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      sops-nix,
      deploy-rs,
      nixos-generators,
      poetry2nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      toplevel@{
        inputs,
        inputs',
        self,
        withSystem,
        ...
      }:
      {
        flake =
          {
            overlays = {
              inputs = final: prev: { inherit inputs; };
              deploy-rs = inputs.deploy-rs.overlays.default;
              spos-nix = inputs.sops-nix.overlays.default;
              poetry2nix = poetry2nix.overlays.default;
              samba-ad-dc = (
                final: prev: {
                  # Rebuild Samba with LDAP, MDNS and Domain Controller support
                  samba =
                    let
                      adSamba = prev.samba.override {
                        enableLDAP = true;
                        enableMDNS = true;
                        enableDomainController = true;
                      };
                    in
                    adSamba.overrideAttrs (
                      final2: prev2: {
                        pythonPath = [
                          prev.python3Packages.dnspython
                          prev.python3Packages.requests
                          prev.python3Packages.cryptography
                          prev.tdb
                        ];
                      }
                    );
                }
              );
            };
            checks = builtins.mapAttrs (
              system: deployLib: deployLib.deployChecks self.deploy
            ) inputs.deploy-rs.lib;
          }
          // (
            let
              systems = {
                otakudc = rec {
                  system = "x86_64-linux";
                  modules = [
                    ./otakudc/configuration.nix
                    {
                      config.activeDirectory = {
                        domain = "otakulan.net";
                        workgroup = "OTAKULAN";
                        netbiosName = "OTAKUDC";
                      };
                      config.env = {
                        # Samba runs its own DNS server on the static IP
                        # which pfSense distributes to clients. This allows
                        # resolving names in active directory. We then forward
                        # down the chain to the dns server below (the lan cache
                        # dns) which intercepts CDNs. Finally, that server
                        # forwards upstream.
                        dnsServer = "172.16.2.2";
                        staticIpv4 = "172.16.2.3";
                        # Default gateway not set since we will use the one 
                        # provided via DHCP on the development interface
                        ipv4DefaultDateway = "172.16.2.1";
                        enableDevelopmentNetworkInterface = false;
                      };
                    }
                  ];
                  pkgs = import nixpkgs {
                    inherit system;
                    overlays = builtins.attrValues self.overlays;
                  };
                  hostname = "172.16.2.3";
                  # hostname = "172.17.51.252";
                  magicRollback = true; # set to false when changing net config
                  format = "proxmox-lxc";
                };
                lancache = rec {
                  system = "x86_64-linux";
                  modules = [
                    ./lancache/configuration.nix
                    {
                      config.env = {
                        # Set to a test ip, will need to be changed to the
                        # lancache dns server
                        dnsServer = "172.16.2.1";
                        # dnsServer = "172.17.51.1";
                        staticIpv4 = "172.16.2.2";
                        # Default gateway not set since we will use the one 
                        # provided via DHCP on the development interface
                        ipv4DefaultDateway = "172.16.2.1";
                        enableDevelopmentNetworkInterface = false;
                      };
                    }
                  ];
                  pkgs = import nixpkgs {
                    inherit system;
                    overlays = builtins.attrValues self.overlays;
                  };
                  hostname = "172.16.2.2";
                  # hostname = "172.17.51.251";
                  magicRollback = true; # set to false when changing net config
                  format = "proxmox-lxc";
                };
                monitoring = rec {
                  system = "x86_64-linux";
                  modules = [
                    ./monitoring/configuration.nix
                    {
                      config.env = {
                        # Set to a test ip, will need to be changed to the
                        # lancache dns server
                        dnsServer = "172.16.2.1";
                        # dnsServer = "172.17.51.1";
                        staticIpv4 = "172.16.2.5";
                        # Default gateway not set since we will use the one
                        # provided via DHCP on the development interface
                        ipv4DefaultDateway = "172.16.2.1";
                        enableDevelopmentNetworkInterface = false;
                      };
                    }
                    sops-nix.nixosModules.sops
                  ];
                  pkgs = import nixpkgs {
                    inherit system;
                    overlays = builtins.attrValues self.overlays;
                  };
                  hostname = "172.16.2.5";
                  # hostname = "172.17.51.200";
                  magicRollback = true; # set to false when changing net config
                  format = "proxmox-lxc";
                };
                builder = rec {
                  system = "x86_64-linux";
                  modules = [
                    ./builder/configuration.nix
                    {
                      config.env = {
                        extraSshKeys = [
                          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKZxPYKNECyOZ1llRiRdDXljH6WE1v7mB12b5bqjF9RZ"
                        ];
                        # Set to a test ip, will need to be changed to the
                        # lancache dns server
                        dnsServer = "172.16.2.1";
                        # dnsServer = "172.17.51.1";
                        staticIpv4 = "172.16.2.6";
                        # Default gateway not set since we will use the one
                        # provided via DHCP on the development interface
                        ipv4DefaultDateway = "172.16.2.1";
                        enableDevelopmentNetworkInterface = false;
                      };
                    }
                    sops-nix.nixosModules.sops
                  ];
                  pkgs = import nixpkgs {
                    inherit system;
                    overlays = builtins.attrValues self.overlays;
                  };
                  hostname = "172.16.2.6";
                  # hostname = "172.17.51.249";
                  magicRollback = false; # set to false when changing net config
                  format = "proxmox-lxc";
                };
                lanparty-seating = rec {
                  system = "x86_64-linux";
                  modules = [
                    ./lanparty-seating/configuration.nix
                    {
                      config.env = {
                        # Set to a test ip, will need to be changed to the
                        # lancache dns server
                        dnsServer = "172.16.2.1";
                        # dnsServer = "172.17.51.1";
                        staticIpv4 = "172.16.2.7";
                        # Default gateway not set since we will use the one
                        # provided via DHCP on the development interface
                        ipv4DefaultDateway = "172.16.2.1";
                        enableDevelopmentNetworkInterface = false;
                      };
                    }
                    sops-nix.nixosModules.sops
                  ];
                  pkgs = import nixpkgs {
                    inherit system;
                    overlays = builtins.attrValues self.overlays;
                  };
                  hostname = "172.16.2.7";
                  # hostname = "172.17.51.249";
                  magicRollback = false; # set to false when changing net config
                  format = "proxmox-lxc";
                };
                vpn = rec {
                  system = "x86_64-linux";
                  modules = [
                    ./vpn/configuration.nix
                    {
                      config.env = {
                        # Set to a test ip, will need to be changed to the
                        # lancache dns server
                        dnsServer = "172.16.2.1";
                        # dnsServer = "172.17.51.1";
                        staticIpv4 = "172.16.2.8";
                        # Default gateway not set since we will use the one
                        # provided via DHCP on the development interface
                        ipv4DefaultDateway = "172.16.2.1";
                        enableDevelopmentNetworkInterface = false;
                      };
                    }
                    # sops-nix.nixosModules.sops
                  ];
                  pkgs = import nixpkgs {
                    inherit system;
                    overlays = builtins.attrValues self.overlays;
                  };
                  hostname = "172.16.2.8";
                  # hostname = "172.17.51.249";
                  magicRollback = false; # set to false when changing net config
                  format = "proxmox-lxc";
                };
              };

              inherit (nixpkgs) lib;

              combine = a: b: a // b;
              combineAll = list: builtins.foldl' combine { } list;
              allAttrNames = list: builtins.attrNames (combineAll list);
              merge =
                list:
                combineAll (map (key: { ${key} = combineAll (builtins.catAttrs key list); }) (allAttrNames list));

              # we aren't using the nixosSystem from the target nixpkgs but it likely doesn't matter
              generateNixosSystems = builtins.mapAttrs (
                name: system:
                lib.nixosSystem {
                  inherit (system) system pkgs;
                  modules = system.modules ++ [ ./common.nix ];
                  specialArgs = {
                    inherit inputs;
                  };
                }
              );

              generateVmImages =
                systems:
                lib.mapAttrsToList (name: system: {
                  ${system.system}.${name} = (
                    nixos-generators.nixosGenerate {
                      inherit (system) pkgs format;
                      modules = system.modules ++ [ ./common.nix ];
                      specialArgs = {
                        inherit inputs;
                      };
                    }
                  );
                }) systems;

              generateDeployRsProfiles =
                systems:
                lib.mapAttrsToList (name: system: {
                  nodes.${name} = {
                    inherit (system) hostname magicRollback;
                    profiles.system = {
                      sshUser = "root";
                      user = "root";
                      path = inputs.deploy-rs.lib.${system.system}.activate.nixos self.nixosConfigurations.${name};
                    };
                  };
                }) systems;

              mergeVmImages = systems: merge (generateVmImages systems);

              mergeDeployRsProfiles = systems: merge (generateDeployRsProfiles systems);
            in
            {
              nixosConfigurations = generateNixosSystems systems;
              packages = mergeVmImages systems;
              deploy = mergeDeployRsProfiles systems;
            }
          );
        systems = [
          # systems for which you want to build the `perSystem` attributes
          "x86_64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
          # ...
        ];
        perSystem =
          moduleArgs@{
            config,
            system,
            lib,
            pkgs,
            ...
          }:
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = builtins.attrValues (toplevel.config.flake.overlays or [ ]);
            };

            devShells.default = pkgs.mkShell {
              name = "otakulan-infra";

              nativeBuildInputs = with pkgs; [ sops-import-keys-hook ];

              sopsPGPKeyDirs = [ ./secrets/keys ];

              buildInputs = with pkgs; [
                jq
                git
                nixfmt-rfc-style
                opentofu
                sops
                yamllint
                gnupg
                ssh-to-pgp
                deploy-rs.defaultPackage.${system}
              ];

              shellHook = ''
                # echo Touch the YubiKey.
                # set -a
                # eval "$(sops --decrypt --output-type dotenv secrets/terraform-backend.yaml)"
                # set +a
              '';
            };

            devShells.cisco-configs = pkgs.mkShell {
              name = "cisco-configs";
              buildInputs = with pkgs; [
                (pkgs.poetry2nix.mkPoetryEnv {
                  projectDir = ./cisco-configs;
                  overrides = (
                    let
                      poetryOverride = (old: { nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.poetry ]; });
                    in
                    pkgs.poetry2nix.overrides.withDefaults (
                      self: super: {
                        # Need to upstream this...
                        # https://github.com/nix-community/poetry2nix/blob/master/overrides/build-systems.json
                        netutils = super.netutils.overridePythonAttrs poetryOverride;
                        ttp = super.ttp.overridePythonAttrs poetryOverride;
                        ttp-templates = super.ttp-templates.overridePythonAttrs poetryOverride;
                      }
                    )
                  );
                })
                poetry
              ];
            };
          };
      }
    );
}
