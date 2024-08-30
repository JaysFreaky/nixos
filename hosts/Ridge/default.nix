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
      desktops = {    # gnome, hyprland, kde
        #gnome.enable = true;
      };

      hardware = {    # amdgpu, audio, bluetooth, fp_reader, nvidia
        amdgpu.enable = true;
        bluetooth.enable = true;
      };

      # "1password", alacritty, flatpak, gaming, kitty, syncthing, wezterm
      #"1password".enable = true;
      gaming.enable = true;
    };


    ##########################################################
    # System Packages / Variables
    ##########################################################
    environment.systemPackages = with pkgs; [ ];

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
      flags = [
        "--commit-lock-file"
      ];
      flake = inputs.self.outPath;
      randomizedDelaySec = "45min";
      rebootWindow = {
        lower = "02:00";
        upper = "06:00";
      };
    };


    ##########################################################
    # Home Manager
    ##########################################################
    home-manager.users.${vars.user} = {
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
        gpuHW = "devices/pci0000:00/0000:00:03.1/0000:08:00.0/0000:09:00.0/0000:0a:00.0";
        fanHW = "devices/platform/nct6775.656";
        cpuHW = "devices/pci0000:00/0000:00:18.3";
      in {
        enable = true;
        config = ''
          INTERVAL=10
          DEVPATH=hwmon1=${gpuHW} hwmon2=${fanHW} hwmon3=${cpuHW}
          DEVNAME=hwmon1=amdgpu hwmon2=nct6798 hwmon3=zenpower
          FCTEMPS=hwmon2/pwm1=hwmon1/temp1_input hwmon2/pwm2=hwmon3/temp2_input
          FCFANS=hwmon2/pwm1=hwmon2/fan1_input hwmon2/pwm2=hwmon2/fan2_input
          MINTEMP=hwmon2/pwm1=40 hwmon2/pwm2=40
          MAXTEMP=hwmon2/pwm1=80 hwmon2/pwm2=80
          # Always spin @ MINPWM until MINTEMP
          MINSTART=hwmon2/pwm1=0 hwmon2/pwm2=0
          MINSTOP=hwmon2/pwm1=64 hwmon2/pwm2=64
          # Fans @ 25% until 40 degress
          MINPWM=hwmon2/pwm1=64 hwmon2/pwm2=64
          # Fans ramp to set max @ 80 degrees - Case: 55% / CPU: 85%
          MAXPWM=hwmon2/pwm1=140 hwmon2/pwm2=217
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
      systemctl restart gpu_uv.service
    '';

    #services.hardware.openrgb.enable = true;

    # Create a service to undervolt GPU
    systemd.services.gpu_uv = let
      gpuUV = pkgs.writeShellScriptBin "gpu_uv.sh" ''
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
        ExecStart = ''${gpuUV}/bin/gpu_uv.sh'';
        ExecReload = ''${gpuUV}/bin/gpu_uv.sh'';
      };
    };


    ##########################################################
    # Boot
    ##########################################################
    boot = {
      initrd = {
        availableKernelModules = [ ];
        kernelModules = [
          "nfs"
        ];
        # Required for Plymouth (password prompt)
        systemd.enable = true;
      };

      # Zenpower uses same PCI device as k10temp, so disabling k10temp
      blacklistedKernelModules = [ "k10temp" ];
      kernelModules = [
        "nct6775"
        "zenpower"
      ];
      extraModulePackages = with config.boot.kernelPackages; [
        zenpower
      ];
      # CachyOS kernel relies on chaotic.scx
      kernelPackages = pkgs.linuxPackages_cachyos;
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
        theme = "rog_2";
        themePackages = [
          # Overriding installs the one theme instead of all 80, reducing the required size
          # Theme previews: https://github.com/adi1090x/plymouth-themes
          (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "rog_2" ]; })
        ];
      };

      supportedFilesystems = [ "btrfs" ];
    };

    chaotic.scx = {
      enable = true;
      scheduler = "scx_lavd";
    };


    ##########################################################
    # Network
    ##########################################################

  };
}
