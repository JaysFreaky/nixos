{
  cfgOpts,
  lib,
  pkgs,
  ...
}: let
  cfg = cfgOpts.hardware.bluetooth;
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

        # 6.11.x Bluetooth suspend/resume fixes
        "bluetooth-suspend" = {
          before = [ "sleep.target" ];
          description = "Soft block Bluetooth on suspend/hibernate";
          wantedBy = [ "hibernate.target" "suspend.target" "suspend-then-hibernate.target" ];
          serviceConfig = {
            ExecStart = ''${lib.getExe' pkgs.util-linux "rfkill"} block bluetooth'';
            ExecStartPost = ''${lib.getExe' pkgs.coreutils "sleep"} 3'';
            RemainAfterExit = true;
            Type = "oneshot";
          };
          unitConfig.StopWhenUnneeded = true;
        };
        "bluetooth-resume" = {
          after = [ "hibernate.target" "suspend.target" "suspend-then-hibernate.target" ];
          description = "Unblock Bluetooth on resume";
          wantedBy = [ "hibernate.target" "suspend.target" "suspend-then-hibernate.target" ];
          serviceConfig = {
            ExecStart = ''${lib.getExe' pkgs.util-linux "rfkill"} unblock bluetooth'';
            Type = "oneshot";
          };
        };
      };
    })

    # PS4 controller pairability
    (lib.mkIf (cfg.enable && cfgOpts.gaming.enable) {
      hardware.bluetooth.input.General = {
        ClassicBondedOnly = false;
        #IdleTimeout = 20;           # Minutes
        #LEAutoSecurity = false;
        #UserspaceHID = true;
      };
    })
  ];
}
