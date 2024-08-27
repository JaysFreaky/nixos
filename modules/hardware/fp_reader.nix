{ config, lib, pkgs, ... }: let
  cfg = config.myOptions.hardware.fp_reader;
in {
  options.myOptions.hardware.fp_reader.enable = lib.mkEnableOption "Fingerprint reader";

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {
      environment.systemPackages = [ pkgs.fprintd ];
      services.fprintd.enable = lib.mkForce true;
    })

    (lib.mkIf (!cfg.enable) {
      services.fprintd.enable = lib.mkForce false;
    })

  ];
}
