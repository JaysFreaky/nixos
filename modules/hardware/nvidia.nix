{ config, lib, pkgs, ... }: let
  cfg = config.myOptions.hardware.nvidia;
  cfg-de = config.myOptions.desktops;
in {
  options.myOptions.hardware.nvidia.enable = lib.mkEnableOption "Nvidia GPU";

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {
      boot.kernelParams = [
        "nvidia.NVreg_EnableResizableBar=1"
        "nvidia.NVreg_TemporaryFilePath=/var/tmp"
      ];

      environment.systemPackages = with pkgs; [ nvtopPackages.nvidia ];

      hardware = {
        graphics.enable = true;
        nvidia = {
          # "nvidia-drm.modeset=1" / "nvidia-drm.fbdev=1" enables dedicated framebuffer
          modesetting.enable = true;
          # Nvidia settings application
          nvidiaSettings = true;
          # Starting with 560, open drivers are used by default
          open = false;
          # beta or stable
          package = config.boot.kernelPackages.nvidiaPackages.stable;
          powerManagement = {
            # "nvidia.NVreg_PreserveVideoMemoryAllocations=1" / enables nvidia-hibernate/resume/sleep.services
              # enable if graphical corruption on resumption from sleep
            enable = true;
            # Experimental: Turns off GPU when not in use - cannot be used with nvidia.prime.sync
            finegrained = false;
          };
        };
      };

      programs.gamescope.args = [ "-F nis" ];

      services.xserver.videoDrivers = [ "nvidia" ];
    })

    (lib.mkIf (cfg.enable && cfg-de.hyprland.enable) {
      environment = {
        sessionVariables = {
          __GL_GSYNC_ALLOWED = 1;
          __GL_VRR_ALLOWED = 1;
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          # GBM could possibily cause Firefox to crash - comment out if so
          GBM_BACKEND = "nvidia_drm";
          # Hardware Accelaration - 'nvidia' or 'vdpau'
          LIBVA_DRIVER_NAME = "nvidia";
          NVD_BACKEND = "direct";
        };

        systemPackages = with pkgs; [ egl-wayland ];
      };
    })

    (lib.mkIf (cfg.enable && cfg-de.kde.enable) {
      # Disable GSP Mode - Smoother Plasma Wayland experience
      boot.kernelParams = [ "nvidia.NVreg_EnableGpuFirmware=0" ];
    })

  ];
}
