{ config, inputs, lib, pkgs, vars, ... }: let
  cfg-hypr = config.myOptions.desktops.hyprland;
  host = config.myHosts;

  fancontrol-gui = inputs.fancontrol-gui.packages.${pkgs.system}.default;
in {
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
        #hyprland.enable = true;
        kde = {
          enable = true;
          gpuWidget = "gpu/gpu1/temperature";
        };
      };

      hardware = {    # amdgpu, audio, bluetooth, fp_reader, nvidia
        bluetooth.enable = true;
        nvidia.enable = true;
      };

      # "1password", alacritty, flatpak, gaming, kitty, syncthing, wezterm
      "1password".enable = true;
      gaming.enable = true;
      syncthing.enable = true;
    };


    ##########################################################
    # System Packages / Variables
    ##########################################################
    environment.systemPackages = with pkgs; [
      # Hardware
        fancontrol-gui          # Fancontrol GUI for lm-sensors
        polychromatic           # Razer lighting GUI

      # Messaging
        #discord                 # Discord

      # Multimedia
        #mpv                     # Media player
        #plex-media-player       # Plex client

      # Notes
        #obsidian                # Markdown notes
    ];

    programs = {
      # PWM fan control
      coolercontrol.enable = false;

      gamescope = {
        # lspci -nn | grep -i vga
        args = [
          "--prefer-vk-device \"10de:2684\""
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

      spicetify = let spice-pkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system}; in {
        enable = true;
        theme = spice-pkgs.themes.text;
        colorScheme = "TokyoNightStorm";
        enabledExtensions = with spice-pkgs.extensions; [
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

    users.users.${vars.user}.extraGroups = [ "fancontrol" ];


    ##########################################################
    # Home Manager
    ##########################################################
    home-manager.users.${vars.user} = {
      # lspci -D | grep -i vga
      programs.mangohud.settings = {
        gpu_voltage = true;
        gpu_fan = true;
        pci_dev = "0:01:00.0";
        table_columns = lib.mkForce 6;
      };

      wayland.windowManager.hyprland.settings = lib.mkIf (cfg-hypr.enable) {
        # 'hyprctl monitors all' - "name, widthxheight@rate, position, scale"
        #monitor = lib.mkForce [ "eDP-1, ${host.width}x${host.height}@${host.refresh}, 0x0, ${host.scale}" ];
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
      # Control case/cpu fans
      fancontrol = {
        enable = false;
        config = let
          fanPath = "devices/platform/nct6687.2592";
          fanName ="nct6686";
          cpuPath = "devices/pci0000:00/0000:00:18.3";
          cpuName = "zenpower";
          # Value = percent * 2.55
          caseMin = "102"; # 40%
          caseMax = "102"; # 40%
          cpuMin = "64"; # 25%
          cpuMax = "217"; # 85%
        in ''
          INTERVAL=10
          DEVPATH=hwmon0=${fanPath} hwmon3=${cpuPath}
          DEVNAME=hwmon0=${fanName} hwmon3=${cpuName}
          FCTEMPS=hwmon0/pwm1=hwmon3/temp1_input hwmon0/pwm2=hwmon3/temp1_input
          FCFANS=hwmon0/pwm1=hwmon0/fan1_input hwmon0/pwm2=hwmon0/fan2_input
          MINTEMP=hwmon0/pwm1=40 hwmon0/pwm2=40
          MAXTEMP=hwmon0/pwm1=80 hwmon0/pwm2=80
          # Always spin @ MINPWM until MINTEMP
          MINSTART=hwmon0/pwm1=30 hwmon0/pwm2=30
          MINSTOP=hwmon0/pwm1=${cpuMin} hwmon0/pwm2=${caseMin}
          # Fans @ 25%/40% until 40 degress
          MINPWM=hwmon0/pwm1=${cpuMin} hwmon0/pwm2=${caseMin}
          # Fans ramp to 85%/40% @ 80 degrees
          MAXPWM=hwmon0/pwm1=${cpuMax} hwmon0/pwm2=${caseMax}
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

      nvidia.prime = {
        amdgpuBusId = "PCI:13:0:0";
        nvidiaBusId = "PCI:1:0:0";
        sync.enable = true;
      };

      openrazer = {
        enable = true;
        users = [ "${vars.user}" ];
      };
    };

    services.hardware.openrgb.enable = true;


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
        "nct6687"
        "zenpower"
      ];
      extraModulePackages = with config.boot.kernelPackages; [
        nct6687d
        zenpower
      ];
      # CachyOS kernel relies on chaotic.scx
      kernelPackages = if (!config.chaotic.scx.enable)
        then pkgs.linuxPackages_latest
        else pkgs.linuxPackages_cachyos;
      kernelParams = [
        "amd_pstate=active"
        # Disable iGPU
        #"module_blacklist=amdgpu"
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
          #efiInstallAsRemovable = true;
          efiSupport = true;
          memtest86.enable = true;
          theme = pkgs.sleek-grub-theme.override { withStyle = "dark"; };
          useOSProber = true;
          #users.${vars.user}.hashedPasswordFile = "/etc/users/grub";
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

  };
}
