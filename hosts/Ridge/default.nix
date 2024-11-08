{ config, inputs, lib, pkgs, vars, ... }: {
  imports = [
    ./filesystems.nix
    ./hardware-configuration.nix
  ];

  options.myHosts = with lib; {
    width = mkOption {
      default = "2560";
      type = types.str;
    };
    height = mkOption {
      default = "1440";
      type = types.str;
    };
    refresh = mkOption {
      default = "144";
      type = types.str;
    };
    scale = mkOption {
      default = "1.25";
      type = types.str;
    };
  };

  config = {
    ##########################################################
    # Custom Options
    ##########################################################
    myOptions = {
      desktops = {    # gnome, kde
        #gnome.enable = true;
      };

      hardware = {    # amdgpu, audio, bluetooth
        amdgpu.enable = true;
        bluetooth.enable = true;
      };

      # "1password", alacritty, flatpak, gaming, kitty, openrgb, plex, syncthing
      #"1password".enable = true;
      gaming.enable = true;
      openrgb.enable = true;
      #plex.enable = true;
      #syncthing.enable = true;
    };


    ##########################################################
    # System Packages / Variables
    ##########################################################
    environment = {
      systemPackages = with pkgs; [ ];
      # Set Firefox to use GPU for video codecs
      variables.MOZ_DRM_DEVICE = "$(stat /dev/dri/* | grep card | cut -d':' -f 2 | tr -d ' ')";
    };

    # lspci -nn | grep -i vga
    programs.gamescope.args = [
      #"--prefer-vk-device \"1002:73a5\""
      #"--borderless"
      "--fullscreen"
    ];

    services = {
      displayManager.autoLogin = {
        enable = lib.mkForce true;
        user = "${vars.user}";
      };
      xserver = {
        enable = true;
        displayManager.gdm.enable = true;
      };
    };

    systemd.services = {
      "autovt@tty1".enable = false;
      "getty@tty1".enable = false;
    };

    system.autoUpgrade = {
      enable = false;
      allowReboot = true;
      dates = "weekly";
      flags = [ "--commit-lock-file" ];
      flake = inputs.self.outPath;
      randomizedDelaySec = "45min";
      rebootWindow = {
        lower = "02:00";
        upper = "06:00";
      };
    };

    system.stateVersion = "24.11";


    ##########################################################
    # Home Manager
    ##########################################################
    home-manager.users.${vars.user} = {
      home.stateVersion = "24.11";

      # lspci -D | grep -i vga
      programs.mangohud.settings = {
        gpu_voltage = true;
        gpu_fan = true;
        pci_dev = "0:0a:00.0";
        table_columns = lib.mkForce 6;
      };
    };


    ##########################################################
    # Hardware
    ##########################################################
    hardware = {
      # Control CPU / case fans
      fancontrol = let 
        cpuMon = "hwmon3";
        cpuName = "zenpower";
        cpuPath = "devices/pci0000:00/0000:00:18.3";
        fanMon = "hwmon2";
        fanName = "nct6798";
        fanPath = "devices/platform/nct6775.656";
        gpuMon = "hwmon1";
        gpuName = "amdgpu";
        gpuPath = "devices/pci0000:00/0000:00:03.1/0000:08:00.0/0000:09:00.0/0000:0a:00.0";
      in {
        enable = true;
        config = ''
          INTERVAL=10
          DEVPATH=${gpuMon}=${gpuPath} ${fanMon}=${fanPath} ${cpuMon}=${cpuPath}
          DEVNAME=${gpuMon}=${gpuName} ${fanMon}=${fanName} ${cpuMon}=${cpuName}
          FCTEMPS=${fanMon}/pwm1=${gpuMon}/temp1_input ${fanMon}/pwm2=${cpuMon}/temp2_input
          FCFANS=${fanMon}/pwm1=${fanMon}/fan1_input ${fanMon}/pwm2=${fanMon}/fan2_input
          MINTEMP=${fanMon}/pwm1=40 ${fanMon}/pwm2=40
          MAXTEMP=${fanMon}/pwm1=80 ${fanMon}/pwm2=80
          # Always spin @ MINPWM until MINTEMP
          MINSTART=${fanMon}/pwm1=0 ${fanMon}/pwm2=0
          MINSTOP=${fanMon}/pwm1=64 ${fanMon}/pwm2=64
          # Fans @ 25% until 40 degress
          MINPWM=${fanMon}/pwm1=64 ${fanMon}/pwm2=64
          # Fans ramp to set max @ 80 degrees - Case: 55% / CPU: 85%
          MAXPWM=${fanMon}/pwm1=140 ${fanMon}/pwm2=217
        '';
      };

      graphics = {
        extraPackages = with pkgs; [
          libva1
          libva-vdpau-driver
          libvdpau-va-gl
        ];
        extraPackages32 = with pkgs.driversi686Linux; [
          libva-vdpau-driver
          libvdpau-va-gl
        ];
      };

      xone.enable = true;
    };

    # Restart GPU undervolt service upon resume
    powerManagement.resumeCommands = ''
      systemctl restart gpu-uv.service
    '';

    # Create a service to undervolt GPU
    systemd.services.gpu-uv = let
      gpuUV = pkgs.writeShellScriptBin "gpu-uv" ''
        #!/usr/bin/env bash
        # Find persistant GPU path: readlink -f /sys/class/drm/card#/device
        GPU=/sys/devices/pci0000\:00/0000\:00\:03.1/0000\:08\:00.0/0000\:09\:00.0/0000\:0a\:00.0

        # GPU min clock - default min is 500
        echo "Setting GPU min clock"
        echo s 0 2100 | tee "$GPU"/pp_od_clk_voltage
        # GPU max clock - default max is 2664
        echo "Setting GPU max clock"
        echo s 1 2200 | tee "$GPU"/pp_od_clk_voltage
        # Voltage offset - default mV is 1200
        echo "Setting voltage offset"
        echo vo -150 | tee "$GPU"/pp_od_clk_voltage
        # VRAM max clock - default max is 1124 - not adjusting
        #echo "Setting VRAM clock"
        #echo m 1 1124 | tee "$GPU"/pp_od_clk_voltage
        # Apply values
        echo "Applying undervolt settings"
        echo c | tee "$GPU"/pp_od_clk_voltage

        # Power usage limit - default wattage is 284 (first 3 numbers are watts)
        echo "Setting power usage limit"
        echo 300000000 | tee "$GPU"/hwmon/hwmon1/power1_cap

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
        ExecStart = ''${lib.getExe gpuUV}'';
        ExecReload = ''${lib.getExe gpuUV}'';
      };
    };


    ##########################################################
    # Boot
    ##########################################################
    boot = {
      initrd = {
        availableKernelModules = [ ];
        kernelModules = [ "nfs" ];
        systemd.enable = true;
      };

      # Zenpower uses same PCI device as k10temp, so disabling k10temp
      blacklistedKernelModules = [ "k10temp" ];
      kernelModules = [
        "nct6775"
        "zenpower"
      ];
      extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
      kernelPackages = if (config.chaotic.scx.enable) then pkgs.linuxPackages_cachyos else pkgs.linuxPackages_latest;
      kernelParams = [
        "amd_pstate=active"
        # Undervolt GPU - https://wiki.archlinux.org/title/AMDGPU#Boot_parameter
        "amdgpu.ppfeaturemask=0xffffffff"
        # Hides text prior to plymouth boot logo
        "quiet"
      ];

      loader = {
        efi = {
          #canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };
        grub = {
          enable = true;
          configurationLimit = 5;
          device = "nodev";
          efiInstallAsRemovable = true;
          efiSupport = true;
          memtest86.enable = true;
          theme = pkgs.sleek-grub-theme.override { withStyle = "dark"; };
          useOSProber = true;
          #users.${vars.user}.hashedPasswordFile = "/etc/users/grub";
        };
        timeout = 1;
      };

      plymouth = {
        enable = true;
        # Theme previews: https://github.com/adi1090x/plymouth-themes
        theme = "rog_2";
        # Overriding installs the one theme instead of all 80, reducing the required size
        themePackages = [ (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "${config.boot.plymouth.theme}" ]; }) ];
      };

      supportedFilesystems = [ "btrfs" ];
    };

    chaotic.scx = {
      enable = true;
      package = pkgs.scx.full;
      scheduler = "scx_lavd";
    };


    ##########################################################
    # Network
    ##########################################################
    networking.hostName = "Ridge";

  };
}
