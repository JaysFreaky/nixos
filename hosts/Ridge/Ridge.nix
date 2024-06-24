{ config, host, inputs, lib, pkgs, vars, ... }:
let
  # GPU Undervolting
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

  refreshRate = "144";
in {
  imports = lib.optional (builtins.pathExists ./swap.nix) ./swap.nix;

  ##########################################################
  # Custom Options
  ##########################################################
  # Desktop - gnome, hyprland
  gnome.enable = true;

  # Hardware - audio (on by default), bluetooth, fp_reader
  bluetooth.enable = true;

  # Programs / Features - 1password, alacritty, flatpak, gaming, kitty, lact, syncthing
  # Whichever terminal is defined in flake.nix is auto-enabled
  "1password".enable = true;
  lact.enable = true;
  syncthing.enable = true;


  ##########################################################
  # System-Specific Packages / Variables
  ##########################################################
  environment = {
    systemPackages = with pkgs; [
    # Gaming
      heroic                  # Game launcher for: Epic, GOG, Prime

    # Hardware
      polychromatic           # Razer lighting GUI

    # Messaging
      discord                 # Discord

    # Monitoring
      amdgpu_top              # GPU stats
      nvtopPackages.amd       # GPU stats
      zenmonitor              # CPU stats

    # Multimedia
      mpv                     # Media player
      plex-media-player       # Plex player
      spotify                 # Music

    # Notes
      obsidian                # Markdown notes
    ];
  };

  jovian = {
    hardware.has.amd.gpu = true;
    steam = {
      enable = true;
      # Start in Steam UI
      autoStart = false;
      # Switch to desktop - Use 'gamescope-wayland' for no desktop
      desktopSession = "gnome";
      user = "${vars.user}";
    };
    steamos = {
      useSteamOSConfig = true;
      enableMesaPatches = true;
    };
  };

  programs = {
    gamescope = {
      enable = true;
      args = [
        "--adaptive-sync"
        #"--borderless"
        "--expose-wayland"
        "--filter fsr"
        "--fullscreen"
        "--framerate-limit ${refreshRate}"
        "--hdr-enabled"
        #"--mangoapp"  # Toggling doesn't work with this
        "--nested-height 1440"
        "--nested-refresh ${refreshRate}"
        "--nested-width 2560"
        #"--prefer-vk-device \"1002:73a5\""  # lspci -nn | grep -i vga
        "--rt"
      ];
    };

    steam = {
      enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
      localNetworkGameTransfers.openFirewall = true;
      remotePlay.openFirewall = true;
    };
  };

  services = {
    displayManager.autoLogin = {
      enable = lib.mkForce false;
      user = "${vars.user}";
    };

    # Disable GDM if jovian.steam.autoStart is enabled
    xserver.displayManager.gdm.enable = lib.mkForce (!config.jovian.steam.autoStart);
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
  # Home Manager Options
  ##########################################################
  home-manager.users.${vars.user} = {
    programs.mangohud = {
      enable = true;
      enableSessionWide = false;
      settings = {
        # lspci -D | grep -i vga
        pci_dev = "0:0a:00.0";
        position = "top-left";
        toggle_hud = "Shift_R+F12";

        round_corners = 10;
        background_alpha = "0.4";
        #background_color = "000000";
        #font_size = 24;
        #text_color = "FFFFFF";
        table_columns = 6;

        cpu_text = "CPU";
        cpu_stats = true;
        cpu_load_change = true;
        cpu_load_value = "50,90";
        cpu_load_color = "FFFFFF,FFAA7F,CC0000";
        cpu_temp = true;
        cpu_power = true;

        gpu_text = "GPU";
        gpu_stats = true;
        gpu_load_change = true;
        gpu_load_value = "50,90";
        gpu_load_color = "FFFFFF,FFAA7F,CC0000";
        gpu_temp = true;
        gpu_power = true;
        gpu_voltage = true;
        gpu_fan = true;

        fsr = true;
        hdr = true;
        gl_vsync = "-1";
        vsync = "0";

        fps = true;
        fps_limit = refreshRate;
        fps_limit_method = "late";
        #gamemode = true;
        #mangoapp_steam = true;
        ram = true;
        time = true;
        vulkan_driver = true;
      };
    };

    # OpenRGB autostart
    xdg.configFile."autostart/OpenRGB.desktop".text = ''
      [Desktop Entry]
      Categories=Utility;
      Comment=OpenRGB 0.9, for controlling RGB lighting.
      Exec=${pkgs.openrgb}/bin/.openrgb-wrapped --startminimized
      Icon=OpenRGB
      Name=OpenRGB
      StartupNotify=true
      Terminal=false
      Type=Application
    '';
  };

  users.users.${vars.user}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAMoEb31xABf0fovDku5zBfBDI2sKCixc31wndQj5VhT jays@FW13"
  ];


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
    #bluetooth.powerOnBoot = lib.mkForce true;

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
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        amdvlk
        libvdpau-va-gl
        rocmPackages.clr
        rocmPackages.clr.icd
        vaapiVdpau
      ];
      extraPackages32 = with pkgs.driversi686Linux; [
        amdvlk
        libvdpau-va-gl
        vaapiVdpau
      ];
    };

    openrazer = {
      enable = true;
      users = [ "${vars.user}" ];
    };

    xone.enable = true;
  };

  # Restart GPU undervolt service upon resume
  powerManagement.resumeCommands = ''
    systemctl restart gpu_uv.service
  '';

  services.hardware.openrgb.enable = true;

  # Create a service to auto undervolt GPU
  systemd.services.gpu_uv = {
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
  # Boot / Encryption
  ##########################################################
  boot = {
    initrd = {
      availableKernelModules = [ ];
      kernelModules = [
        "amdgpu"
        "nfs"
      ];
      # Required for Plymouth (password prompt)
      systemd.enable = true;
    };

    # Increase stability/performance of games
    kernel.sysctl."vm.max_map_count" = lib.mkForce 2147483642;

    # Zenpower uses same PCI device as k10temp, so disabling k10temp
    blacklistedKernelModules = [ "k10temp" ];
    kernelModules = [
      "nct6775"
      "zenpower"
    ];
    extraModulePackages = with config.boot.kernelPackages; [
      zenpower
    ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "amd_pstate=active"
      # Undervolt GPU - https://wiki.archlinux.org/title/AMDGPU#Boot_parameter
      "amdgpu.ppfeaturemask=0xffffffff"
      #"quiet"
      #"splash"
    ];

    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub = {
        enable = false;
        configurationLimit = 5;
        device = "nodev";
        efiSupport = true;
        enableCryptodisk = false;
        memtest86.enable = true;
        theme = pkgs.sleek-grub-theme.override { withStyle = "dark"; };
        useOSProber = true;
        users.${vars.user}.hashedPasswordFile = "/etc/users/grub";
      };
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        # Console resolution
        consoleMode = "auto";
        editor = false;
        memtest86.enable = true;
      };
      timeout = 1;
    };

    plymouth = {
      enable = false;
      theme = "rog_2";
      themePackages = [
        # Overriding installs the one theme instead of all 80, reducing the required size
        # Theme previews: https://github.com/adi1090x/plymouth-themes
        (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "rog_2" ]; })
      ];
    };

    supportedFilesystems = [ "btrfs" ];
  };


  ##########################################################
  # Network
  ##########################################################
  networking = {
    hostName = host.hostName;
    # Interfaces not needed with NetworkManager enabled
    networkmanager.enable = true;
  };


  ##########################################################
  # Filesystems
  ##########################################################
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-partlabel/root";
      fsType = "btrfs";
      options = [
        "compress=zstd"
        "noatime"
        "subvol=root"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-partlabel/boot";
      fsType = "vfat";
    };

    "/home" = {
      device = "/dev/disk/by-partlabel/root";
      fsType = "btrfs";
      options = [
        "compress=zstd"
        "subvol=home"
      ];
    };

    "/nix" = {
      device = "/dev/disk/by-partlabel/root";
      fsType = "btrfs";
      options = [
        "compress=zstd"
        "noatime"
        "subvol=nix"
      ];
    };

    "/nas" = {
      device = "10.0.10.10:/mnt/user";
      fsType = "nfs";
      options = [
        "noauto"
        "x-systemd.automount"
        "x-systemd.device-timeout=5s"
        "x-systemd.idle-timeout=600"
        "x-systemd.mount-timeout=5s"
      ];
    };
  };

}
