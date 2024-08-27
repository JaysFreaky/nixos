{ config, lib, ... }: let
  cfg = config.myOptions.hardware.bluetooth;
in {
  options.myOptions.hardware.bluetooth.enable = lib.mkEnableOption "Bluetooth";

  config = lib.mkIf (cfg.enable) {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          ControllerMode = "dual";
          # A2DP support
          Enable = "Source,Sink,Media,Socket";
          # Battery level display
          Experimental = true;
        };
      };
    };

    services.blueman.enable = true;

  };
}
