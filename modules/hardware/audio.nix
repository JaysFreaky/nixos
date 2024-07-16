{ config, lib, pkgs, ... }: with lib; {
  options.audio.enable = mkOption {
    default = true;
    type = types.bool;
  };

  config = mkMerge [
    (mkIf (config.audio.enable) {
      environment.systemPackages = with pkgs; [
        #pavucontrol    # Pulse audio control
        pwvucontrol    # Pipewire audio control
      ];

      # Required for pipewire to work
      hardware.pulseaudio.enable = false;

      # Real-time audio enablement
      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        jack.enable = true;
        pulse.enable = true;
        wireplumber.enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
      };
    })

    (mkIf (config.hyprland.enable) {
      sound.mediaKeys.enable = true;
    })
  ];

}
