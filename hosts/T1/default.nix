{ config, inputs, lib, pkgs, vars, ... }: let
  cfg = config.myOptions.desktops;
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
          #gpuWidget2 = "gpu/gpu1/temperature";
        };
      };

      hardware = {    # amdgpu, audio, bluetooth, fp_reader, nvidia
        bluetooth.enable = true;
        nvidia.enable = true;
      };

      # "1password", alacritty, flatpak, gaming, kitty, openrgb, plex, syncthing, wezterm
      "1password".enable = true;
      gaming.enable = true;
      openrgb.enable = true;
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
        colorScheme = "CatppuccinMacchiato";
        enabledExtensions = with spice-pkgs.extensions; [
          fullAlbumDate
          hidePodcasts
          savePlaylists
          wikify
        ];
      };
    };

    services.fwupd.enable = true;
    system.stateVersion = "24.05";
    users.users.${vars.user}.extraGroups = [ "fancontrol" ];


    ##########################################################
    # Home Manager
    ##########################################################
    home-manager.users.${vars.user} = {
      home.stateVersion = "24.05";

      # lspci -D | grep -i vga
      programs.mangohud.settings = {
        gpu_voltage = true;
        gpu_fan = true;
        pci_dev = "0:01:00.0";
        table_columns = lib.mkForce 6;
      };

      wayland.windowManager.hyprland.settings = lib.mkIf (cfg.hyprland.enable) {
        # 'hyprctl monitors all' - "name, widthxheight@rate, position, scale"
        #monitor = with host; lib.mkForce [ "eDP-1, ${width}x${height}@${refresh}, 0x0, ${scale}" ];
      };
    };


    ##########################################################
    # Hardware
    ##########################################################
    hardware = {
      fancontrol = {
        enable = true;
        config = let
        # Hardware
          cpuMon = "hwmon1";
          cpuName = "k10temp";
          cpuPath = "devices/pci0000:00/0000:00:18.3";
          fanMon = "hwmon2";
          fanName = "nct6686";
          fanPath = "devices/platform/nct6687.2592";
        # Fan speeds -- value = percent * 2.55
          caseMin = "100"; # 40%
          caseMax = "102"; # 40%
          cpuMin = "64"; # 25%
          cpuMax = "217"; # 85%
        in ''
          INTERVAL=10
          DEVPATH=${cpuMon}=${cpuPath} ${fanMon}=${fanPath}
          DEVNAME=${cpuMon}=${cpuName} ${fanMon}=${fanName}
          FCTEMPS=${fanMon}/pwm1=${cpuMon}/temp1_input ${fanMon}/pwm2=${cpuMon}/temp1_input
          FCFANS=${fanMon}/pwm1=${fanMon}/fan1_input ${fanMon}/pwm2=${fanMon}/fan2_input
          MINTEMP=${fanMon}/pwm1=40 ${fanMon}/pwm2=40
          MAXTEMP=${fanMon}/pwm1=80 ${fanMon}/pwm2=80
          MINSTART=${fanMon}/pwm1=30 ${fanMon}/pwm2=30
          MINSTOP=${fanMon}/pwm1=${cpuMin} ${fanMon}/pwm2=${caseMin}
          # Fans @ 25%/40% until 40 degress
          MINPWM=${fanMon}/pwm1=${cpuMin} ${fanMon}/pwm2=${caseMin}
          # CPU fan ramps to 85% @ 80 degrees
          MAXPWM=${fanMon}/pwm1=${cpuMax} ${fanMon}/pwm2=${caseMax}
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
        #sync.enable = true;
      };

      openrazer = {
        enable = true;
        users = [ "${vars.user}" ];
      };
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
        "amdgpu"  # Disable iGPU
      ];
      kernelModules = [ "nct6687" ];
      extraModulePackages = with config.boot.kernelPackages; [ nct6687d ];
      # 6.10.11 until 6.11.x supports Nvidia sleep/resume
      kernelPackages = if (config.chaotic.scx.enable) then pkgs.linuxPackages_cachyos else pkgs.linuxPackages_6_10;
      kernelParams = [
        "amd_pstate=active"
        "quiet"
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
        timeout = 3;
      };

      plymouth = {
        enable = true;
        # Theme previews: https://github.com/adi1090x/plymouth-themes
        theme = "loader";
        # Overriding installs a single theme instead of all 80, reducing the required size
        themePackages = [ (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "${config.boot.plymouth.theme}" ]; }) ];
      };

      supportedFilesystems = [ "btrfs" ];
    };

    chaotic.scx = {
      enable = true;
      scheduler = "scx_rusty";
    };

  };
}
