{ lib, pkgs, config, ... }:
with lib;
let cfg = config.env;
in {
  options.env = {
    activeDirectory = {
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
  };
}
