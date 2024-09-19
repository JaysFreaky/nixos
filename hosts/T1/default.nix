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
          gpuWidget = "gpu/gpu0/temperature";
          gpuWidget2 = "gpu/gpu1/temperature";
        };
      };

      hardware = {    # amdgpu, audio, bluetooth, fp_reader, nvidia
        bluetooth.enable = true;
        nvidia.enable = true;
      };

      # "1password", alacritty, flatpak, gaming, kitty, plex, syncthing, wezterm
      "1password".enable = true;
      gaming.enable = true;
      plex.enable = true;
      syncthing.enable = true;
    };


    ##########################################################
    # System Packages / Variables
    ##########################################################
    environment = {
      systemPackages = with pkgs; [
      # Hardware
        fancontrol-gui          # Fancontrol GUI for lm-sensors
        polychromatic           # Razer lighting GUI

      # Messaging
        discord                 # Discord

      # Multimedia
        haruna                  # MPV frontend
        kdePackages.dragon      # Media player
        mpc-qt                  # MPV frontend
        #mpv                     # Media player
        #smplayer                # MPV frontend

      # Notes
        obsidian                # Markdown notes
      ];

      # Set Firefox to use GPU for video codecs
      variables.MOZ_DRM_DEVICE = "/dev/dri/by-path/pci-0000:01:00.0-render";
    };

    programs = {
      # PWM fan control
      #coolercontrol.enable = true;

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

    users.users.${vars.user}.extraGroups = [
      "fancontrol"
      "i2c"
    ];


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
    };


    ##########################################################
    # Hardware
    ##########################################################
    hardware = {
      fancontrol = {
        enable = true;
        config = let
          fanPath = "devices/platform/nct6687.2592";
          fanName ="nct6686";
          cpuPath = "devices/pci0000:00/0000:00:18.3";
          cpuName = "k10temp";
          # Value = percent * 2.55
          caseMin = "100"; # 40%
          caseMax = "102"; # 40%
          cpuMin = "64"; # 25%
          cpuMax = "217"; # 85%
        in ''
          INTERVAL=10
          DEVPATH=hwmon1=${cpuPath} hwmon2=${fanPath}
          DEVNAME=hwmon1=${cpuName} hwmon2=${fanName}
          FCTEMPS=hwmon2/pwm1=hwmon1/temp1_input hwmon2/pwm2=hwmon1/temp1_input
          FCFANS=hwmon2/pwm1=hwmon2/fan1_input hwmon2/pwm2=hwmon2/fan2_input
          MINTEMP=hwmon2/pwm1=40 hwmon2/pwm2=40
          MAXTEMP=hwmon2/pwm1=80 hwmon2/pwm2=80
          # Always spin @ MINPWM until MINTEMP
          MINSTART=hwmon2/pwm1=30 hwmon2/pwm2=30
          MINSTOP=hwmon2/pwm1=${cpuMin} hwmon2/pwm2=${caseMin}
          # Fans @ 25%/40% until 40 degress
          MINPWM=hwmon2/pwm1=${cpuMin} hwmon2/pwm2=${caseMin}
          # Fans ramp to 85%/40% @ 80 degrees
          MAXPWM=hwmon2/pwm1=${cpuMax} hwmon2/pwm2=${caseMax}
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

      i2c.enable = true;

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

    services.hardware.openrgb = {
      enable = true;
      package = pkgs.openrgb-with-all-plugins;
    };


    ##########################################################
    # Boot
    ##########################################################
    boot = {
      initrd = {
        availableKernelModules = [ ];
        kernelModules = [ "nfs" ];
        # Required for Plymouth (password prompt)
        systemd.enable = true;
      };

      blacklistedKernelModules = [
        #"amdgpu"  # Disable iGPU
      ];
      kernelModules = [ "nct6687" ];
      extraModulePackages = with config.boot.kernelPackages; [ nct6687d ];
      # CachyOS kernel relies on chaotic.scx
      kernelPackages = if (!config.chaotic.scx.enable)
        then pkgs.linuxPackages_latest
        else pkgs.linuxPackages_cachyos;
      kernelParams = [
        "amd_pstate=active"
        "quiet"  # Hides text prior to plymouth boot logo
      ];

      loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
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
        enable = true;
        theme = "loader";
        themePackages = [
          # Overriding installs a single theme instead of all 80, reducing the required size
            # Theme previews: https://github.com/adi1090x/plymouth-themes
          (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "loader" ]; })
        ];
      };

      supportedFilesystems = [ "btrfs" ];
    };

    chaotic.scx = {
      enable = true;
      scheduler = "scx_lavd";
    };

  };
}
