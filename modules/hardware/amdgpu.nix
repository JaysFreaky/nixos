{
  lib,
  pkgs,
  cfgOpts,
  ...
}: let
  cfg = cfgOpts.hardware.amdgpu;
in {
  options.myOptions.hardware.amdgpu = {
    enable = lib.mkEnableOption "AMDGPU";
    undervolt = {
      enable = lib.mkEnableOption "AMDGPU undervolting support";
      gpu = lib.mkOption {
        description = "GPU's persistant path can be found by running: 'readlink -f /sys/class/drm/card*/device'";
        example = "/sys/devices/pci0000:00/.../.../...";
        type = lib.types.str;
      };
      clockMin = lib.mkOption {
        description = "GPU's minimum clock speed";
        example = 500;
        type = lib.types.int;
      };
      clockMax = lib.mkOption {
        description = "GPU's maximum clock speed";
        example = 2664;
        type = lib.types.int;
      };
      powerLimit = lib.mkOption {
        description = "GPU's power limit via wattage (first 3 digits are watts)";
        example = 284000000;
        type = lib.types.int;
      };
      voltOffset = lib.mkOption {
        description = "GPU's negative voltage offset";
        example = -150;
        type = lib.types.int;
      };
      vramClock = lib.mkOption {
        description = "GPU's VRAM maximum clock speed";
        example = 1124;
        type = lib.types.int;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {
      environment.systemPackages = builtins.attrValues {
        inherit (pkgs)
          amdgpu_top    # GPU stats
          lact          # AMDGPU controller
        ;
      } ++ [
        pkgs.nvtopPackages.amd  # GPU stats
      ];

      hardware = {
        amdgpu = {
          # Disabling amdvlk to use mesa unless specifically required
          amdvlk = {
            # hardware.graphics.extraPackages: pkgs.amdvlk
            #enable = true;
            # hardware.graphics.extraPackages32: pkgs.driversi686Linux.amdvlk
            #support32Bit.enable = true;
          };

          # boot.initrd.kernelModules: "amdgpu"
          initrd.enable = true;
          # hardware.graphics.extraPackages: pkgs.rocmPackages.clr/.icd
          opencl.enable = true;
        };

        graphics = {
          # Mesa drivers
          enable = true;
          enable32Bit = true;

          # Hardware acceleration
          extraPackages = builtins.attrValues {
            inherit (pkgs)
              libva1
              libva-vdpau-driver
              libvdpau-va-gl
            ;
          };
          extraPackages32 = builtins.attrValues {
            inherit (pkgs.driversi686Linux)
              libva-vdpau-driver
              libvdpau-va-gl
            ;
          };
        };
      };

      programs.gamescope.args = [ "-F fsr" ];
      services.xserver.enable = true;

      # LACT daemon service
      systemd = {
        # Create service from package
        packages = [ pkgs.lact ];
        # Autostart service at boot
        services.lactd.wantedBy = [ "multi-user.target" ];
      };
    })

    (lib.mkIf (cfg.enable && cfg.undervolt.enable) {
      # Undervolt GPU - https://wiki.archlinux.org/title/AMDGPU#Boot_parameter
      boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];

      # Restart GPU undervolt service upon resume
      powerManagement.resumeCommands = "systemctl restart amdgpu-undervolt.service";

      # Create a service to undervolt GPU
      systemd.services.amdgpu-undervolt = let
        gpuScript = pkgs.writeShellScriptBin "amdgpu-uv" ''
          GPU='${cfg.undervolt.gpu}'

          echo "Setting GPU min clock"
          echo s 0 ${builtins.toString cfg.undervolt.clockMin} | tee "$GPU"/pp_od_clk_voltage
          echo "Setting GPU max clock"
          echo s 1 ${builtins.toString cfg.undervolt.clockMax} | tee "$GPU"/pp_od_clk_voltage
          echo "Setting voltage offset"
          echo vo ${builtins.toString cfg.undervolt.voltOffset} | tee "$GPU"/pp_od_clk_voltage
          #echo "Setting VRAM max clock"
          #echo m 1 ${builtins.toString cfg.undervolt.vramClock} | tee "$GPU"/pp_od_clk_voltage
          echo "Applying undervolt settings"
          echo c | tee "$GPU"/pp_od_clk_voltage
          echo "Setting power usage limit"
          echo ${builtins.toString cfg.undervolt.powerLimit} | tee "$GPU"/hwmon/hwmon1/power1_cap

          # Performance level: auto, low, high, manual
          echo "Setting performance level"
          echo manual | tee "$GPU"/power_dpm_force_performance_level
          # Power level mode: cat pp_power_profile_mode
          echo "Setting power level mode to 3D Fullscreen"
          echo 1 | tee "$GPU"/pp_power_profile_mode
          # GPU power states: cat pp_dpm_sclk
          echo "Enabling all GPU power states"
          echo 2 | tee "$GPU"/pp_dpm_sclk
          # VRAM power states: cat pp_dpm_mclk
          echo "Enabling all VRAM power states"
          echo 3 | tee "$GPU"/pp_dpm_mclk
        '';
      in {
        after = [ "multi-user.target" "rc-local.service" "systemd-user-sessions.service" ];
        description = "Set AMDGPU Undervolt";
        wantedBy = [ "multi-user.target" ];
        wants = [ "modprobe@amdgpu.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          ExecStart = "${lib.getExe gpuScript}";
          ExecReload = "${lib.getExe gpuScript}";
        };
      };
    })
  ];
}
