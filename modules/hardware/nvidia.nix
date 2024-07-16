{ config, lib, pkgs, ... }: with lib; {
  options.nvidia.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkMerge [
    (mkIf (config.nvidia.enable) {
      environment.systemPackages = with pkgs; [
        # Monitoring
          nvtopPackages.nvidia    # GPU stats
      ];

      hardware = {
        graphics.extraPackages = with pkgs; [ nvidia-vaapi-driver ];
        nvidia = {
          modesetting.enable = true;
          nvidiaSettings = true;
          # Beta ships 555, which fixes Wayland issues - beta or stable
            package = config.boot.kernelPackages.nvidiaPackages.beta;
          #powerManagement = true;
        };
      };

      services.xserver.videoDrivers = [ "nvidia" ];

      boot = {
        initrd.kernelModules = [
          "nvidia"
          "nvidia_drm"
          "nvidia_modeset"
          "nvidia_uvm"
        ];
        kernelParams = [
          # Nvidia - Suspend
            #"nvidia.NVreg_PreserveVideoMemoryAllocations=1"
          # Nvidia - Framebuffer
            "nvidia_drm.fbdev=1"
          # Nvidia - DKMS
            "nvidia_drm.modeset=1"
        ];
      };
    })

    (mkIf (config.hyprland.enable) {
      environment = {
        sessionVariables = {
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          # Could possibily cause Firefox to crash - remove if so
            GBM_BACKEND = "nvidia_drm";

          __GL_GSYNC_ALLOWED = 1;
          __GL_VRR_ALLOWED = 1;

          # Hardware Accelaration - 'nvidia' or 'vdpau'
            LIBVA_DRIVER_NAME = "nvidia";
          NVD_BACKEND = "direct";
        };

        systemPackages = with pkgs; [
          egl-wayland
        ];
      };
    })
  ];

}
