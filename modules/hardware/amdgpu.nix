{ config, lib, pkgs, ... }: with lib; {
  options.amdgpu.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.amdgpu.enable) {
    boot.kernelParams = [
      # Undervolt GPU - https://wiki.archlinux.org/title/AMDGPU#Boot_parameter
      #"amdgpu.ppfeaturemask=0xffffffff"
    ];

    environment.systemPackages = with pkgs; [
      amdgpu_top            # GPU stats
      lact                  # AMDGPU controller
      nvtopPackages.amd     # GPU stats
    ];

    hardware = {
      amdgpu = {
        amdvlk = {
          # graphics.enable / pkgs.amdvlk
          enable = true;
          # pkgs.driversi686Linux.amdvlk
          support32Bit.enable = true;
        };
        # initrd.kernelModules: "amdgpu"
        initrd.enable = true;
        # pkgs.rocmPackages.clr/.icd
        opencl.enable = true;
      };
      # Not currently enabled via amdgpu.amdvlk
      graphics.enable32Bit = true;
    };

    services.xserver.enable = true;

    # LACT daemon service
    systemd = {
      # Create service from package
      packages = with pkgs; [ lact ];
      # Autostart service at boot
      services.lactd.wantedBy = [ "multi-user.target" ];
    };
  };

}
