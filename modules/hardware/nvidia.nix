{ config, lib, pkgs, ... }: with lib; {
  options.nvidia.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkMerge [
    (mkIf (config.nvidia.enable) {
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
          # kernelParams: "nvidia-drm.modeset=1"
          modesetting.enable = true;
          nvidiaSettings = true;
          # Current beta (555) fixes Wayland issues - beta or stable
          package = config.boot.kernelPackages.nvidiaPackages.beta;
          # kernelParams: "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
          powerManagement.enable = false;
        };
      };

      programs.gamescope.args = [ "-F nis" ];

      # Enabling these enables hardware.nvidia
      services.xserver = {
        enable = true;
        videoDrivers = [ "nvidia" ];
      };
    })

    (mkIf (config.hyprland.enable) {
      environment = {
        sessionVariables = {
          __GL_GSYNC_ALLOWED = 1;
          __GL_VRR_ALLOWED = 1;
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          # GBM could possibily cause Firefox to crash - remove if so
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

    (mkIf (config.kde.enable) {
      boot.kernelParams = [
        # Disable GSP Mode - Smoother Plasma Wayland experience
        "nvidia.NVreg_EnableGpuFirmware=0"
      ];
    })
  ];

}
