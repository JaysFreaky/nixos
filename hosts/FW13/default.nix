{ config, inputs, lib, pkgs, stable, vars, ... }: let
  # Patch kernel to log usbpd instead of warn
  fw-usbpd-charger = pkgs.callPackage ./usbpd { kernel = config.boot.kernelPackages.kernel; };
  protonMB = pkgs.protonmail-bridge-gui;
in {
  imports = [
    ./filesystems.nix
    ./hardware-configuration.nix
  ];

  ##########################################################
  # Custom Options
  ##########################################################
  myHosts = {
    width = "2256";
    height = "1504";
    refresh = "60";
    scale = "1.5";
  };

  myOptions = {
    desktops = {    # cosmic, gnome, hyprland, kde
      gnome.enable = true;
    };

    hardware = {    # amdgpu, audio, bluetooth, fp_reader
      amdgpu.enable = true;
      bluetooth.enable = true;
      #fp_reader.enable = true;
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
    # Email
      protonMB                # GUI bridge for Thunderbird
      thunderbird             # Email client

    # Framework Hardware
      framework-tool          # Swiss army knife for FWs
      fw-ectool               # Embedded controller | 'ectool'
      iio-sensor-proxy        # Ambient light sensor | 'monitor-sensor'
      sbctl                   # Secure boot key manager

    # Messaging
      discord                 # Discord

    # Monitoring
      powertop                # Power stats
      zenmonitor              # CPU stats

    # Multimedia
      celluloid               # MPV GTK frontend w/ Wayland
      clapper                 # GTK media player
      mpv                     # Media player
      smplayer                # MPV frontend

    # Notes
      obsidian                # Markdown notes

    # Productivity
      libreoffice             # Office suite

    # VPN
      protonvpn-gui           # VPN client
    ];

    # Set Firefox to use GPU for video codecs
    variables.MOZ_DRM_DEVICE = "/dev/dri/by-path/pci-0000:c1:00.0-render";
  };

  # lspci -nn | grep -i vga
  programs.gamescope.args = [
    "--prefer-vk-device \"1002:15bf\""
    "--fullscreen"
    #"--borderless"
  ];

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
      "org/gnome/shell/extensions/Battery-Health-Charging" = {
        amend-power-indicator = true;
        bal-end-threshold = 85;
        charging-mode = "bal";
        current-bal-end-threshold = 85;
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

  # Auto-tune on startup
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
    # Auto-tuning - to use powertop bin, pkg must be declared above
    powertop.enable = true;
  };

  services = {
    # Firmware updater
    fwupd = {
      enable = true;
      # Downgrading fwupd is required to modify the fingerprint sensor firmware
        # https://github.com/NixOS/nixos-hardware/tree/master/framework/13-inch/7040-amd
      /*package = (import (builtins.fetchTarball {
        # v1.8.14
        url = "https://github.com/NixOS/nixpkgs/archive/bb2009ca185d97813e75736c2b8d1d8bb81bde05.tar.gz";
        sha256 = "sha256:003qcrsq5g5lggfrpq31gcvj82lb065xvr7bpfa8ddsw8x4dnysk";
        # v1.9.7
        #url = "https://github.com/NixOS/nixpkgs/archive/21ef15cc55ec43c4a5f8d952f58e87d964480b0a.tar.gz";
        #sha256 = "sha256:0q71dz2fivpz7s6n74inrq27y8s6y80z7hhj5b8p0090j4xllia7";
      }) { inherit (pkgs) system; }).fwupd;*/
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
        GPU_DEVICE='/sys/devices/pci0000\:00/0000\:00\:08.1/0000\:c1\:00.0'
        DPM_PERF_LEVEL=low
        PPD=power-saver

        if [ "$1" -eq 1 ] ; then
          DPM_PERF_LEVEL=high
          PPD=performance
        else
          DPM_PERF_LEVEL=low
          PPD=power-saver
        fi

        echo "$DPM_PERF_LEVEL" > "$GPU_DEVICE"/power_dpm_force_performance_level
        #${lib.getExe pkgs.power-profiles-daemon} set "$PPD"
      '';
    in ''
      SUBSYSTEM=="power_supply" RUN+="${lib.getExe powerMode} %E{POWER_SUPPLY_ONLINE}"
    '';

    upower = {
      enable = true;
      percentageLow = 10;
      percentageCritical = 5;
      percentageAction = 2;
      criticalPowerAction = "Hibernate";
    };
  };

  # Sleep for 30m then hibernate
  systemd.sleep.extraConfig = ''
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

    # Zenpower uses same PCI device as k10temp
    blacklistedKernelModules = [ "k10temp" ];
    # Allow 5GHz wifi
    extraModprobeConfig = ''options cfg80211 ieee80211_regdom="US"'';
    extraModulePackages = (with config.boot.kernelPackages; [
      cpupower
      framework-laptop-kmod
      zenpower
    ]) ++ [
      (fw-usbpd-charger.overrideAttrs (_: { patches = [ ./usbpd/usbpd_charger.patch ]; }))
    ];
    kernelModules = [
      "framework_laptop"
      "nfs"
      "zenpower"
    ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      # Mask gpe0B ACPI interrupts
      "acpi_mask_gpe=0x0B"
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
      timeout = 1;
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
    hostName = "FW13";
    networkmanager.wifi = {
      # iwd provides more stability/throughput on AMD FW models
      backend = "iwd";
      macAddress = "stable-ssid";
      powersave = false;
    };
  };

}
