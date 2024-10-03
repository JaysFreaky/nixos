{ config, lib, ... }: let
  cfg = config.myOptions.hardware.bluetooth;
  cfg-gaming = config.myOptions.gaming;
in {
  options.myOptions.hardware.bluetooth.enable = lib.mkEnableOption "Bluetooth";

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {
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

      systemd.services = {
        # Fixes directory mode error in journalctl
        bluetooth.serviceConfig.ConfigurationDirectoryMode = lib.mkForce 0755;
      };
    })

    # PS4 controller pairability
    (lib.mkIf (cfg.enable && cfg-gaming.enable) {
      hardware.bluetooth.input.General = {
        ClassicBondedOnly = false;
        #IdleTimeout = 20;           # Minutes
        #LEAutoSecurity = false;
        #UserspaceHID = true;
      };
    })

  ];
}
