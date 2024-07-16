{ config, host, inputs, lib, pkgs, vars, ... }: let
  resolution = {
    width = "2560";
    height = "1440";
    refreshRate = "144";
    scale = "1.25";
  };
in {
  imports = lib.optional (builtins.pathExists ./swap.nix) ./swap.nix;

  ##########################################################
  # Custom Options
  ##########################################################
  # Desktop - gnome, hyprland
  #gnome.enable = true;
  #hyprland.enable = true;

  # Hardware - audio (on by default), bluetooth, fp_reader
  bluetooth.enable = true;

  # Programs / Features - 1password, alacritty, flatpak, gaming, kitty, lact, syncthing
  # Whichever terminal is defined in flake.nix is auto-enabled
  "1password".enable = true;
  gaming.enable = true;
  syncthing.enable = true;


  ##########################################################
  # System-Specific Packages / Variables
  ##########################################################
  environment = {
    systemPackages = with pkgs; [
      # Hardware
        polychromatic           # Razer lighting GUI

      # Messaging
        #discord                 # Discord

      # Monitoring
        nvtopPackages.nvidia    # GPU stats

      # Multimedia
        #mpv                     # Media player
        #plex-media-player       # Plex player
        #spotify                 # Music

      # Notes
        #obsidian                # Markdown notes
    ];
  };

  programs = {
    # PWM fan control
    coolercontrol.enable = false;

    gamescope = {
      enable = true;
      args = [
        "-W ${resolution.width}"
        "-H ${resolution.height}"
        "-r ${resolution.refreshRate}"
        "-o ${resolution.refreshRate}"        # Unfocused
        "-F fsr"
        "--expose-wayland"
        "--rt"
        #"--prefer-vk-device \"1002:73a5\""   # lspci -nn | grep -i vga
        "--hdr-enabled"
        "--framerate-limit ${resolution.refreshRate}"
        "--fullscreen"
      ];
      capSysNice = true;
      #env = { };
      package = pkgs.gamescope.override {
        enableExecutable = true;
        enableWsi = true;
      };
    };
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
    programs.mangohud.settings = {
      fps_limit = resolution.refreshRate;
      gpu_voltage = true;
      gpu_fan = true;
      # lspci -D | grep -i vga
      #pci_dev = "0:0a:00.0";
      table_columns = lib.mkForce 6;
    };

  /*wayland.windowManager.hyprland.settings = {
      # hyprctl monitors all
      # name,resolution@htz,position,scale
      monitor = [
        ",preferred,auto,auto"
        #"eDP-1,2560x1440@144,0x0,${resolution.scale}"
      ];
    }; */

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


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
    bluetooth.powerOnBoot = lib.mkForce true;

    # Control CPU / case fans
    fancontrol = let 
      #gpuHW = "devices/pci0000:00/0000:00:03.1/0000:08:00.0/0000:09:00.0/0000:0a:00.0";
      gpuHW = "";
      gpuDrv = "nvidia";
      fanHW = "devices/platform/nct6775.656";
      fanDrv ="nct6798";
      cpuHW = "devices/pci0000:00/0000:00:18.3";
      cpuDrv = "zenpower";
    in {
      enable = false;
      config = ''
        INTERVAL=10
        DEVPATH=hwmon1=${gpuHW} hwmon2=${fanHW} hwmon3=${cpuHW}
        DEVNAME=hwmon1=${gpuDrv} hwmon2=${fanDrv} hwmon3=${cpuDrv}
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
        libva1
        libva-vdpau-driver
        libvdpau-va-gl
        nvidia-vaapi-driver
      ];
      extraPackages32 = with pkgs.driversi686Linux; [
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };

    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      # Beta ships 555, which fixes Wayland issues
      package = config.boot.kernelPackages.nvidiaPackages.beta;
      #powerManagement = true;
    };

    openrazer = {
      enable = true;
      users = [ "${vars.user}" ];
    };
  };

  services = {
    hardware.openrgb.enable = true;

    xserver.videoDrivers = [ "nvidia" ];
  };

  ##########################################################
  # Boot / Encryption
  ##########################################################
  boot = {
    initrd = {
      availableKernelModules = [ ];
      kernelModules = [
        "nfs"
        "nvidia"
        "nvidia_drm"
        "nvidia_modeset"
        "nvidia_uvm"
      ];
      # Required for Plymouth (password prompt)
      systemd.enable = true;
    };

    # Zenpower uses same PCI device as k10temp, so disabling k10temp
    blacklistedKernelModules = [ "k10temp" ];
    kernelModules = [
      #"nct6775"
      "zenpower"
    ];
    extraModulePackages = with config.boot.kernelPackages; [
      zenpower
    ];
    kernelPackages = pkgs.linuxPackages_latest;
    # CachyOS kernel relies on chaotic.scx
    #kernelPackages = pkgs.linuxPackages_cachyos;
    kernelParams = [
      "amd_pstate=active"
      # Nvidia - Suspend
        #"nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      # Nvidia - Framebuffer
        "nvidia_drm.fbdev=1"
      # Nvidia - DKMS
        "nvidia_drm.modeset=1"
      # Hides text prior to plymouth boot logo
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

  /*chaotic.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };*/


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

    "/mnt/nas" = {
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
