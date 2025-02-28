{
  lib,
  pkgs,
  cfgHosts,
  cfgOpts,
  inputs,
  myUser,
  ...
}: {
  imports = [
    ./filesystems.nix
    ./hardware-configuration.nix
  ];

  ##########################################################
  # Custom Options
  ##########################################################
  myHosts = {
    width = 1920;
    height = 1080;
    refresh = 60;
    scale = 1.25;
  };

  myOptions = {
    desktops = {
      cosmic.enable = true;
      hyprland.enable = false;
    };

    hardware.bluetooth.enable = false;

    # "1password", flatpak, kitty, wezterm
    "1password".enable = true;
  };


  ##########################################################
  # System Packages / Variables
  ##########################################################
  environment = {
    systemPackages = [ ];
    # Set Firefox to use GPU for video codecs
    variables.MOZ_DRM_DEVICE = "/dev/dri/by-path/pci-0000:00:02.0-render";
  };

  system.stateVersion = "24.11";


  ##########################################################
  # Home Manager
  ##########################################################
  home-manager.users.${myUser} = let
    hyprApps = cfgOpts.desktops.hyprland.hyprApps;
  in {
    imports = [ inputs.plasma-manager.homeManagerModules.plasma-manager ];
    home.stateVersion = "24.11";

    programs = {
      plasma = lib.mkIf (cfgOpts.desktops.kde.enable) {
        configFile."kcminputrc"."Libinput/1739/0/Synaptics TM3053-004" = {
          "ClickMethod" = 2;
          "NaturalScroll" = true;
          "PointerAccelerationProfile" = 1;
          "ScrollFactor" = 0.5;
          "TapDragLock" = true;
        };
      };

      waybar.settings = lib.mkIf (cfgOpts.desktops.hyprland.enable) {
        mainBar = {
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

    wayland.windowManager.hyprland = lib.mkIf (cfgOpts.desktops.hyprland.enable) {
      settings = {
        # 'hyprctl monitors all' : name, widthxheight@rate, position, scale
        monitor = [ "eDP-1, ${builtins.toString cfgHosts.width}x${builtins.toString cfgHosts.height}@${builtins.toString cfgHosts.refresh}, 0x0, ${builtins.toString cfgHosts.scale}" ];
        bind = [
          ", XF86AudioMute, exec, ${hyprApps.pw-volume} mute toggle"
          #", XF86, exec, amixer sset Capture toggle"  # Mic disabled in firmware
          #", XF86Display, ," # Presentation mode?
          #", XF86WLAN, ," # Disables wifi by default
          #", XF86Tools, ," # Settings shortcut?
          #", XF86Search, ," # rofi search?
          #", XF86LaunchA, exec, rofi -show drun"  # rofi launcher
          #", XF86Explorer, exec, kitty spf"
        ];
        # Hold for continuous adjustment
        binde = [
          ", XF86AudioLowerVolume, exec, ${hyprApps.pw-volume} change -5%"
          ", XF86AudioRaiseVolume, exec, ${hyprApps.pw-volume} change +5%"
          ", XF86MonBrightnessDown, exec, ${hyprApps.brightnessctl} s 10%-"
          ", XF86MonBrightnessUp, exec, ${hyprApps.brightnessctl} s +10%"
        ];
      };
    };
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware.graphics = {
    # Packages (listed for context) are imported from nixos-hardware/common/gpu/intel through T450s module
    /*
    extraPackages = builtins.attrValues {
      inherit (pkgs)
        intel-compute-runtime
        intel-media-driver
        intel-vaapi-driver
        vpl-gpu-rt
      ;
    };
    extraPackages32 = builtins.attrValues {
      inherit (pkgs.driversi686Linux)
        intel-media-driver
        intel-vaapi-driver
      ;
    };
    */
  };


  ##########################################################
  # Boot
  ##########################################################
  boot = {
    initrd.systemd.enable = true;

    kernelModules = [ "nfs" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "quiet" ];

    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
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

    supportedFilesystems = [
      "btrfs"
      "nfs"
    ];
  };


  ##########################################################
  # Network
  ##########################################################
}
