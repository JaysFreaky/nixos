{ config, lib, pkgs, ... }: let
  cfg = config.myOptions.hardware.nvidia;
  cfg-hypr = config.myOptions.desktops.hyprland;
  cfg-kde = config.myOptions.desktops.kde;
in {
  options.myOptions.hardware.nvidia.enable = lib.mkEnableOption "Nvidia GPU";

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {
      boot.kernelParams = [
        # Enable dedicated framebuffer - https://wiki.archlinux.org/title/NVIDIA#DRM_kernel_mode_setting
        "nvidia-drm.fbdev=1"
      ];

      environment.systemPackages = with pkgs; [
        nvtopPackages.nvidia    # GPU stats
      ];

      hardware = {
        graphics.enable = true;
        nvidia = {
          # "nvidia-drm.modeset=1"
          modesetting.enable = true;
          # Nvidia settings application
          nvidiaSettings = true;
          # Starting with 560, open drivers are used by default
          open = false;
          # beta or stable
          package = config.boot.kernelPackages.nvidiaPackages.stable;
          powerManagement = {
            # "nvidia.NVreg_PreserveVideoMemoryAllocations=1" - enable if graphical corruption on sleep resume
            enable = false;
            # Experimental - Turns off GPU when not in use
            finegrained = false;
          };
        };
      };

      programs.gamescope.args = [ "-F nis" ];

      # Enabling these enables hardware.nvidia
      services.xserver = {
        enable = true;
        videoDrivers = [ "nvidia" ];
      };
    })

    (lib.mkIf (cfg.enable && cfg-hypr.enable) {
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

        systemPackages = with pkgs; [
          egl-wayland
        ];
      };
    })

    (lib.mkIf (cfg.enable && cfg-kde.enable) {
      boot.kernelParams = [
        # Disable GSP Mode - Smoother Plasma Wayland experience
        "nvidia.NVreg_EnableGpuFirmware=0"
      ];
      # Does the same thing as above?
      #hardware.nvidia.gsp.enable = false;
    })

  ];
}
