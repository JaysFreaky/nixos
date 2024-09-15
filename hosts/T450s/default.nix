{ config, lib, pkgs, vars, ... }: let
  cfg-hypr = config.myOptions.desktops.hyprland;
  cfg-kde = config.myOptions.desktops.kde;
  host = config.myHosts;
in {
  imports = [
    ./filesystems.nix
    ./hardware-configuration.nix
  ];

  options.myHosts = with lib; {
    width = mkOption {
      default = "1920";
      type = types.str;
    };
    height = mkOption {
      default = "1080";
      type = types.str;
    };
    refresh = mkOption {
      default = "60";
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
        #bluetooth.enable = true;
      };

      # "1password", alacritty, flatpak, gaming, kitty, syncthing, wezterm
      "1password".enable = true;
    };


    ##########################################################
    # System Packages / Variables
    ##########################################################
    environment = {
      systemPackages = with pkgs; [ ];
      # Set Firefox to use GPU for video codecs
      variables.MOZ_DRM_DEVICE = "/dev/dri/by-path/pci-0000:00:02.0-render";
    };


    ##########################################################
    # Home Manager
    ##########################################################
    home-manager.users.${vars.user} = let
      hyprApps = cfg-hypr.hyprApps;
    in {
      programs = {
        plasma = lib.mkIf (cfg-kde.enable) {
          configFile."kcminputrc"."Libinput/1739/0/Synaptics TM3053-004" = {
            "ClickMethod" = 2;
            "NaturalScroll" = true;
            "PointerAccelerationProfile" = 1;
            "ScrollFactor" = 0.5;
            "TapDragLock" = true;
          };
        };

        waybar.settings = lib.mkIf (cfg-hypr.enable) {
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

      wayland.windowManager.hyprland = lib.mkIf (cfg-hypr.enable) {
        settings = {
          # 'hyprctl monitors all' : name, widthxheight@rate, position, scale
          monitor = [ "eDP-1, ${host.width}x${host.height}@${host.refresh}, 0x0, ${host.scale}" ];
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
      # extraPackages imported from nixos-hardware/lenovo/T450s through nixos-hardware/common/gpu/intel
      extraPackages = [ ];
      extraPackages32 = with pkgs.driversi686Linux; [
        intel-media-driver
        intel-vaapi-driver
      ];
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

  };
}
