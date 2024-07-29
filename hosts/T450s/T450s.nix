{ config, host, lib, pkgs, vars, ... }: {
  imports = lib.optional (builtins.pathExists ./swap.nix) ./swap.nix;

  ##########################################################
  # Custom Options
  ##########################################################
  # Desktop - gnome, hyprland
  #gnome.enable = true;
  hyprland.enable = true;
  #kde.enable = true;

  # Hardware - audio (on by default), bluetooth, fp_reader, nvidia
  bluetooth.enable = false;

  # Programs / Features - alacritty, flatpak, gaming, kitty, syncthing
  # Whichever terminal is defined in flake.nix is auto-enabled
  "1password".enable = true;


  ##########################################################
  # System-Specific Packages / Variables
  ##########################################################
  environment = {
    sessionVariables = lib.mkMerge [
      ({
        # Session
      })
      (lib.mkIf (config.hyprland.enable) {
        # Scaling
        #GDK_SCALE = host.resScale;
        #QT_AUTO_SCREEN_SCALE_FACTOR = host.resScale;
      })
    ];
    systemPackages = with pkgs; [
      # Category
        cowsay
    ];
  };


  ##########################################################
  # Home Manager Options
  ##########################################################
  home-manager.users.${vars.user} = {
    programs = {
      plasma = lib.mkIf (config.kde.enable) {
        configFile."kcminputrc"."Libinput/1739/0/Synaptics TM3053-004" = {
          "ClickMethod" = 2;
          "NaturalScroll" = true;
          "PointerAccelerationProfile" = 1;
          "TapDragLock" = true;
        };
      };

      waybar.settings = lib.mkIf (config.hyprland.enable) {
        mainBar = let hyprApps = config.hyprApps; in {
          # CPU Temperature
          "temperature#cpu" = {
            hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon"; #hwmon6
            input-filename = "temp1_input";
            interval = 5;
            format = "  {temperatureC}°C";
            on-click = "${hyprApps.terminal} ${hyprApps.btop}";
            tooltip = true;
            tooltip-format = "{temperatureF}°Freedom Units";
          };

          # GPU Temperature
          "temperature#gpu" = {
            hwmon-path-abs = "/sys/devices/";
            input-filename = "temp2_input";
            interval = 5;
            format = "󰢮  {temperatureC}°C";
            on-click = "${hyprApps.terminal} ${hyprApps.nvtop}";
            tooltip = true;
            tooltip-format = "{temperatureF}°Freedom Units";
          };

          # Battery 1
          "battery#bat0" = {
            bat = "BAT0";
            adapter = "AC";
            interval = 5;
            states = {
              warning = 25;
              critical = 10;
            };
            format = "{icon} {capacity}%";
            format-time = "{H}h:{M}m";
            format-icons = [ " " " " " " " " " " ];
            format-charging = "{capacity}%";
            format-plugged = " {capacity}%";
            tooltip = true;
            tooltip-format = "{time}";
          };

          # Battery 2
          "battery#bat1" = {
            bat = "BAT1";
            adapter = "AC";
            interval = 5;
            states = {
              warning = 25;
              critical = 10;
            };
            format = "{icon} {capacity}%";
            format-time = "{H}h:{M}m";
            format-icons = [ " " " " " " " " " " ];
            format-charging = "{capacity}%";
            format-plugged = " {capacity}%";
            tooltip = true;
            tooltip-format = "{time}";
          };
        };
      };
    };

    wayland.windowManager.hyprland = lib.mkIf (config.hyprland.enable) {
      settings = {
        # 'hyprctl monitors all' : name, widthxheight@rate, position, scale
        monitor = [ "eDP-1, ${host.resWidth}x${host.resHeight}@${host.resRefresh}, 0x0, ${host.resScale}" ];
        
        bind = let hyprApps = config.hyprApps; in [
          # Function key binds
          ", XF86AudioMute, exec, ${hyprApps.pw-volume} mute toggle"
          ", XF86AudioLowerVolume, exec, ${hyprApps.pw-volume} change -5%"
          ", XF86AudioRaiseVolume, exec, ${hyprApps.pw-volume} change +5%"
          #", XF86, exec, amixer sset Capture toggle"  # Mic disabled in firmware
          ", XF86MonBrightnessDown, exec, ${hyprApps.brightnessctl} s 10%-"
          ", XF86MonBrightnessUp, exec, ${hyprApps.brightnessctl} s +10%"
          #", XF86Display, ," # Presentation mode?
          #", XF86WLAN, ," # Disables wifi by default
          #", XF86Tools, ," # Settings shortcut?
          #", XF86Search, ," # rofi search?
          #", XF86LaunchA, exec, rofi -show drun"  # rofi launcher
          #", XF86Explorer, exec, kitty spf"
        ];
      };
    };
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [
        # Imported through nixos-hardware/lenovo/T450s from nixos-hardware/common/gpu/intel
      ];
      extraPackages32 = with pkgs.driversi686Linux; [
        intel-media-driver
        intel-vaapi-driver
      ];
    };
  };


  ##########################################################
  # Boot / Encryption
  ##########################################################
  boot = {
    initrd = {
      availableKernelModules = [ ];
      kernelModules = [ "nfs" ];
      # Required for Plymouth (password prompt)
      systemd.enable = true;
    };

    kernelModules = [ ];
    extraModulePackages = [ ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "quiet"
      "splash"
    ];

    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub = {
        enable = false;
        configurationLimit = 5;
        devices = [ "nodev" ];
        efiSupport = true;
        enableCryptodisk = false;
        memtest86.enable = true;
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
      theme = "nixos-bgrt";
      themePackages = [ pkgs.nixos-bgrt-plymouth ];
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
