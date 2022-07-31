{ config, pkgs, inputs, ... }:

{
  nix = {
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true

      # nop out the global flake registry
      flake-registry = ${builtins.toFile "flake-registry" (builtins.toJSON { version = 2; flakes = [ ]; })}
    '';
    # Pin nixpkgs for older Nix tools
    nixPath = [ "nixpkgs=${pkgs.path}" ];
    settings = {
      trusted-users = [ "root" "@wheel" ];
    };
    registry = {
      self.flake = inputs.self;
      nixpkgs.flake = inputs.nixpkgs;
    };
  };
}
