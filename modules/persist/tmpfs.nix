{ config, lib, pkgs, vars, ... }:
with lib;
{
  options.tmpfs.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.tmpfs.enable) {
    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=2G" "mode=755" ];
    };
  };
}
