{
  config,
  inputs,
  lib,
  pkgs,
  #stable
  vars,
  ...
}: let
  # pkgs or stable
  protonMB = pkgs.protonmail-bridge-gui;
  # Whether to enable the fingerprint reader
  useFP = true;
in {
  imports = [
    ./filesystems.nix
    ./hardware-configuration.nix
  ];

  ##########################################################
  # Custom Options
  ##########################################################
  myHosts = {
    width = 2256;
    height = 1504;
    refresh = 60;
    scale = 1.5;
  };

  myOptions = {
    desktops = {
      cosmic.enable = false;
      gnome.enable = true;
    };

    hardware = {
      amdgpu.enable = true;
      bluetooth.enable = true;
    };

    # "1password", alacritty, flatpak, gaming, kitty, plex, spicetify, stylix, syncthing, wezterm
    "1password".enable = true;
    gaming.enable = true;
    plex.enable = true;
    spicetify.enable = true;
    stylix = {
      enable = true;
      wallpaper = {
        #dark = "${vars.configPath}/assets/wallpapers/FW13/dark.png";
        #light = "${vars.configPath}/assets/wallpapers/FW13/light.png";
      };
    };
    syncthing.enable = true;
    #wezterm.enable = true;
  };


  ##########################################################
  # System Packages / Variables
  ##########################################################
  environment = {
    systemPackages = with pkgs; [
    # Communication
      discord                 # Discord
      protonMB                # GUI bridge for Thunderbird
      thunderbird             # Email client

    # Framework Hardware
      framework-tool          # Swiss army knife for FWs
      iio-sensor-proxy        # Ambient light sensor | 'monitor-sensor'
      sbctl                   # Secure boot key manager

    # Misc
      android-udev-rules      # Android flashing

    # Monitoring
      powertop                # Power stats
      zenmonitor              # CPU stats

    # Multimedia
      #mpv                    # Media player
      #smplayer               # MPV frontend

    # Networking
      protonvpn-gui           # VPN client

    # Productivity
      libreoffice             # Office suite
      obsidian                # Markdown notes
    ] ++ lib.optionals (useFP) [
      fprintd                 # Fingerprint daemon
    ];
    # Set Firefox to use GPU for video codecs
    variables.MOZ_DRM_DEVICE = "/dev/dri/by-path/pci-0000:c1:00.0-render";
  };

  # lspci -nn | grep -i vga
  programs.gamescope.args = [ "--prefer-vk-device \"1002:15bf\"" ];

  system.stateVersion = "24.11";


  ##########################################################
  # Home Manager
  ##########################################################
  home-manager.users.${vars.user} = { config, ... }: let
    ee-pkg = config.services.easyeffects.package;
    eePreset = config.services.easyeffects.preset;
  in {
    #imports = [ ./fetch-logo.nix ];

    dconf.settings = {
      # Automatic screen brightness
      "org/gnome/settings-daemon/plugins/power".ambient-enabled = false;
      "org/gnome/shell".enabled-extensions = [ "Battery-Health-Charging@maniacx.github.com" ];
      "org/gnome/shell/extensions/Battery-Health-Charging" = let
        bal = 85;
        ful = 90;
      in {
        amend-power-indicator = true;
        bal-end-threshold = bal;
        charging-mode = "ful";
        current-bal-end-threshold = bal;
        current-ful-end-threshold = ful;
        ful-end-threshold = ful;
        indicator-position = 4;
        show-system-indicator = false;
      };
      "org/gnome/shell/extensions/power-profile-switcher" = {
        # performance, balanced, power-saver
        ac = "performance";
        bat = "power-saver";
      };
    };

    home.packages = with pkgs.gnomeExtensions; [ battery-health-charging ];
    home.stateVersion = "24.11";

    # lspci -D | grep -i vga
    programs.mangohud.settings.pci_dev = "0:c1:00.0";

    # https://github.com/FrameworkComputer/linux-docs/tree/main/easy-effects
    services.easyeffects = {
      enable = true;
      preset = "fw13-easy-effects";
    };

    # Workaround for easyeeffects preset not auto loading
      # https://github.com/nix-community/home-manager/issues/5185
    systemd.user.services.easyeffects.Service.ExecStartPost = [ "${lib.getExe ee-pkg} --load-preset ${eePreset}" ];

    xdg.configFile = {
      "autostart/ProtonMailBridge.desktop".text = lib.strings.concatLines [
        (lib.strings.replaceStrings
          [ "Exec=protonmail-bridge-gui" ]
          [ "Exec=${lib.getExe protonMB} --no-window" ]
          (lib.strings.fileContents "${protonMB}/share/applications/proton-bridge-gui.desktop")
        )
        "X-GNOME-Autostart-enabled=true"
      ];
      "easyeffects/output/${eePreset}.json".source = pkgs.fetchFromGitHub {
        owner = "FrameworkComputer";
        repo = "linux-docs";
        rev = "e70bfc83dbdcbcd2cd47259a823a17d5ccce14c2";
        sha256 = "sha256-o4unZQBGD6nejo1KeZ9x6zGOYOHbSq7WtarGOdiu5EM=";
      } + "/easy-effects/${eePreset}.json";
    };
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
    bluetooth.powerOnBoot = lib.mkForce false;
    enableAllFirmware = true;
    firmware = [ pkgs.linux-firmware ];
    #framework.laptop13.audioEnhancement.enable = true;

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

    # Allow 5GHz wifi
    wirelessRegulatoryDatabase = true;
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
    # Auto-tuning - to use powertop bin, pkg must be declared in systemPackages
    powertop.enable = true;
  };

  services = {
    fprintd.enable = lib.mkIf (useFP) true;

    fwupd = {
      enable = true;
      #extraRemotes = ["lvfs-testing"];
    };

    logind = {
      lidSwitch = "suspend";
      powerKey = "suspend-then-hibernate";
      extraConfig = ''
        IdleAction=suspend
        IdleActionSec=10m
      '';
    };

    thermald.enable = true;

    # System performance adjusts when plugged into power - power_dpm_force_performance_level is auto by default
    udev.extraRules = let
      powerMode = pkgs.writeShellScriptBin "power-mode" ''
        #!/usr/bin/env bash
        # Find persistant GPU path: readlink -f /sys/class/drm/card1/device
        GPU='/sys/devices/pci0000\:00/0000\:00\:08.1/0000\:c1\:00.0'
        DPM_PERF_LEVEL=low
        PPD=power-saver

        if [ "$1" -eq 1 ]; then
          DPM_PERF_LEVEL=high
          PPD=performance
        fi

        echo "$DPM_PERF_LEVEL" > "$GPU"/power_dpm_force_performance_level
        #${lib.getExe pkgs.power-profiles-daemon} set "$PPD"
      '';
    in ''SUBSYSTEM=="power_supply" RUN+="${lib.getExe powerMode} %E{POWER_SUPPLY_ONLINE}"'';

    upower = {
      enable = true;
      percentageLow = 15;
      percentageCritical = 10;
      percentageAction = 5;
      criticalPowerAction = "Hibernate";
    };
  };

  # Sleep for 30m then hibernate
  systemd.sleep.extraConfig = ''
    AllowHibernation=yes
    HibernateDelaySec=30m
    HibernateMode=shutdown
    SuspendState=mem
  '';


  ##########################################################
  # Boot
  ##########################################################
  boot = {
    initrd = {
      availableKernelModules = [ "cryptd" ];
      systemd.enable = true;
    };

    blacklistedKernelModules = [
      # For AMD s2_idle.py debugging, as it taints the kernel
      #"framework_laptop"
    ];
    # Allow 5GHz wifi
    extraModprobeConfig = ''options cfg80211 ieee80211_regdom="US"'';
    #extraModulePackages = with config.boot.kernelPackages; [ ];
    kernelModules = [ "nfs" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
    # Testing reduced battery usage during suspend
      "acpi.ec_no_wakeup=1"
      "rtc_cmos.use_acpi_alarm=1"
    # Fixes VP9/VAAPI video glitches
      "amd_iommu=off"
    # Disable IPv6 stack
      "ipv6.disable=1"
    # Hides any text before showing plymouth boot logo
      "quiet"
    ];

    # https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      systemd-boot = {
        enable = if (config.boot.lanzaboote.enable) then lib.mkForce false else true;
        configurationLimit = 5;
        consoleMode = "auto";
        editor = false;
        memtest86.enable = if (config.boot.lanzaboote.enable) then lib.mkForce false else true;
      };
      timeout = 2;
    };

    plymouth = let
      framework-plymouth = inputs.framework-plymouth.packages.${pkgs.system}.default;
    in {
      enable = true;
      theme = "framework";
      themePackages = [ framework-plymouth ];
    };

    supportedFilesystems = [
      "btrfs"
      "nfs"
    ];
  };


  ##########################################################
  # Network
  ##########################################################
  networking = {
    enableIPv6 = false;
    networkmanager.wifi = {
      # iwd provides more stability/throughput on AMD FW models
      backend = "iwd";
      macAddress = "stable-ssid";
      powersave = false;
    };
  };
}
