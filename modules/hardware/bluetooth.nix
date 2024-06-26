{ config, lib, ... }: with lib; {
  options.bluetooth.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.bluetooth.enable) {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;

      settings = {
        General = {
          # A2DP support
          Enable = "Source,Sink,Media,Socket";
          AutoEnable = true;
          ControllerMode = "bredr";

          # Battery level display
          Experimental = true;
        };
      };
    };

    services.blueman.enable = true;
  };

}
