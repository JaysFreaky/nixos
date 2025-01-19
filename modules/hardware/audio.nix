{
  cfgOpts,
  lib,
  pkgs,
  ...
}: let
  cfg = cfgOpts.hardware.audio;
in {
  options.myOptions.hardware.audio.enable = lib.mkEnableOption "Audio";

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [
      #pwvucontrol    # Pipewire audio control
    ];

    # Real-time audio
    security.rtkit.enable = true;

    services = {
      pipewire = {
        enable = true;
        jack.enable = true;
        pulse.enable = true;
        wireplumber.enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
      };

      # Required for pipewire
      pulseaudio.enable = false;
    };
  };
}
