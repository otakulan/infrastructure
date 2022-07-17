{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs@{ self, nixpkgs, flake-utils, sops-nix, deploy-rs
    , nixos-generators, ... }:
    let platforms = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
    in {
      overlays.inputs = final: prev: { inherit inputs; };
    } // inputs.flake-utils.lib.eachSystem platforms (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = builtins.attrValues self.overlays;
        };
        inherit (nixpkgs) lib;
        # Use inputs to avoid infinite recursion
        sops-nix = inputs.sops-nix.packages.${system};
        deploy-rs = inputs.deploy-rs.defaultPackage.${system};
      in {

        devShells = { default = pkgs.mkShell {
          name = "iac-infra";

          nativeBuildInputs = [ sops-nix.sops-import-keys-hook ];

          sopsPGPKeyDirs = [
            ./secrets/keys
          ];

          buildInputs = with pkgs; [
            jq
            git
            nix
            nixfmt
            terraform_1
            sops
            yamllint
            gnupg
            sops-nix.ssh-to-pgp
            deploy-rs
          ];

          shellHook = ''
            # echo Touch the YubiKey.
            # set -a
            # eval "$(sops --decrypt --output-type dotenv secrets/terraform-backend.yaml)"
            # set +a
          '';
        };
      };}) // (let
        systems = {
          proxmox = rec {
            system = "x86_64-linux";
            modules = [
              ./proxmox/configuration.nix
              sops-nix.nixosModules.sops
            ];
            pkgs = import nixpkgs {
              inherit system;
              overlays = builtins.attrValues self.overlays;
            };
            hostname = "172.17.51.242";
            format = "proxmox-lxc";
          };
        };

        inherit (nixpkgs) lib;

        # todo: clean this away into a function
        combine = a: b: a // b;
        combineAll = list: builtins.foldl' combine { } list;
        allAttrNames = list: builtins.attrNames (combineAll list);
        merge = list:
          combineAll
          (map (key: { ${key} = combineAll (builtins.catAttrs key list); })
            (allAttrNames list));

        # we aren't using the nixosSystem from the target nixpkgs but it likely doesn't matter
        generateNixosSystems = builtins.mapAttrs (name: system:
          lib.nixosSystem {
            system = system.system;
            modules = system.modules;
            pkgs = system.pkgs;
          });

        generateVmImages = systems:
          lib.mapAttrsToList (name: system: {
            ${system.system}.${name} = (nixos-generators.nixosGenerate {
              modules = system.modules;
              pkgs = system.pkgs;
              format = system.format;
            });
          }) systems;

        generateDeployRsProfiles = systems:
          lib.mapAttrsToList (name: system: {
            nodes.${name} = {
              hostname = system.hostname;
              profiles.system = {
                sshUser = "root";
                user = "root";
                path = deploy-rs.lib.${system.system}.activate.nixos self.nixosConfigurations.${name};
              };
            };
          }) systems;

        mergeVmImages = systems:
          merge (generateVmImages systems);

        mergeDeployRsProfiles = systems:
          merge (generateDeployRsProfiles systems);
      in {
        nixosConfigurations = generateNixosSystems systems;
        packages = mergeVmImages systems;
        deploy = mergeDeployRsProfiles systems;
      }) // {
        checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      };
}
