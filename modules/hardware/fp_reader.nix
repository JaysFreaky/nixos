{ config, lib, pkgs, ... }:
with lib;
{
  options.fp_reader.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkMerge [
    (mkIf (config.fp_reader.enable) {
      environment.systemPackages = [ pkgs.fprintd ];
      services.fprintd.enable = lib.mkForce true;
    })

    (mkIf (!config.fp_reader.enable) {
      services.fprintd.enable = lib.mkForce false;
    })
  ];
}
