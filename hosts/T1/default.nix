{ config, inputs, lib, pkgs, vars, ... }: let
  cfg-hypr = config.myOptions.desktops.hyprland;
  host = config.myHosts;
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
          #gpuWidget = "gpu/gpu0/temperature";
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


    ##########################################################
    # Home Manager
    ##########################################################
    home-manager.users.${vars.user} = {
      # lspci -D | grep -i vga
      programs.mangohud.settings = {
        gpu_voltage = true;
        gpu_fan = true;
        #pci_dev = "0:0a:00.0";
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


    ##########################################################
    # Network
    ##########################################################

  };
}
