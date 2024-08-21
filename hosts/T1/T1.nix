{ config, host, inputs, lib, pkgs, vars, ... }: {
  imports = lib.optional (builtins.pathExists ./swap.nix) ./swap.nix;

  ##########################################################
  # Custom Options
  ##########################################################
  # Desktop - gnome, hyprland, kde
  #hyprland.enable = true;
  kde.enable = true;

  # Hardware - amdgpu, audio (on by default), bluetooth, fp_reader, nvidia
  bluetooth.enable = true;
  nvidia.enable = true;

  # Programs / Features - 1password, alacritty, flatpak, gaming, kitty, syncthing, wezterm
  # Whichever terminal is defined in flake.nix is auto-enabled in hosts/common.nix, but can enable more
  "1password".enable = true;
  gaming.enable = true;
  syncthing.enable = true;


  ##########################################################
  # System-Specific Packages / Variables
  ##########################################################
  environment.systemPackages = with pkgs; [
    # Hardware
      polychromatic           # Razer lighting GUI

    # Messaging
      #discord                 # Discord

    # Multimedia
      #mpv                     # Media player
      #plex-media-player       # Plex player

    # Notes
      #obsidian                # Markdown notes
  ];

  programs = {
    # PWM fan control
    coolercontrol.enable = false;

    gamescope = {
      # lspci -nn | grep -i vga
      args = [
        #"--prefer-vk-device \"1002:73a5\""
        #"--borderless"
        "--fullscreen"
        "--hdr-enabled"
      ];
      env = {
        DXVK_HDR = "1";
        # Not sure if required with pkgs.gamescope-wsi
        ENABLE_GAMESCOPE_WSI = "1";
      };
    };

    spicetify = let spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system}; in {
      enable = true;
      theme = spicePkgs.themes.text;
      colorScheme = "TokyoNightStorm";
      enabledExtensions = with spicePkgs.extensions; [
        fullAlbumDate
        hidePodcasts
        savePlaylists
        wikify
      ];
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
    # lspci -D | grep -i vga
    programs.mangohud.settings = {
      gpu_voltage = true;
      gpu_fan = true;
      #pci_dev = "0:0a:00.0";
      table_columns = lib.mkForce 6;
    };

    wayland.windowManager.hyprland.settings = lib.mkIf (config.hyprland.enable) {
      # 'hyprctl monitors all' - "name, widthxheight@rate, position, scale"
      #monitor = lib.mkForce [ "eDP-1, ${host.resWidth}x${host.resHeight}@${host.resRefresh}, 0x0, ${host.resScale}" ];
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


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
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

    openrazer = {
      enable = true;
      users = [ "${vars.user}" ];
    };
  };

  #kde.gpuWidget = "gpu/gpu0/temperature";

  services.hardware.openrgb.enable = true;


  ##########################################################
  # Boot / Encryption
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
      theme = "loader";
      themePackages = [
        # Overriding installs the one theme instead of all 80, reducing the required size
        # Theme previews: https://github.com/adi1090x/plymouth-themes
        (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "loader" ]; })
      ];
    };

    supportedFilesystems = [ "btrfs" ];
  };

  chaotic.scx = {
    enable = false;
    scheduler = "scx_lavd";
  };


  ##########################################################
  # Network
  ##########################################################
  # Interfaces not needed with NetworkManager enabled
  networking.networkmanager.enable = true;


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
