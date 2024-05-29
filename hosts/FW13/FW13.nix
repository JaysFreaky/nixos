{ config, host, lib, pkgs, vars, ... }:
let
  # Call boot logo package
  plymouth-fw = pkgs.callPackage ../../packages/plymouth-fw {};
 
  # GPU performance adjustment - power_dpm_force_performance_level is auto by default
  gpuPower = pkgs.writeShellScriptBin "dpm_level.sh" ''
    #!/usr/bin/env bash

    # Find persistant GPU device: readlink -f /sys/class/drm/card1/device
    gpuDevice=/sys/devices/pci0000\:00/0000\:00\:08.1/0000\:c1\:00.0

    # Default level
    DPM_PERF_LEVEL=low
    # Evaluate argument passed by udev
    if [ $1 -eq 1 ] ; then
      DPM_PERF_LEVEL=high
    else
      DPM_PERF_LEVEL=low
    fi

    # Set performance level
    echo $DPM_PERF_LEVEL > "$gpuDevice"/power_dpm_force_performance_level
  '';
in {
  imports = lib.optional (builtins.pathExists ./swap.nix) ./swap.nix;

  ##########################################################
  # Custom Options
  ##########################################################
  # Desktop - gnome, hyprland
  gnome.enable = true;

  # Hardware - audio (on by default), bluetooth, fp_reader
  bluetooth.enable = true;

  # Programs / Features - 1password, alacritty, flatpak, gaming, kitty, syncthing
  # Whichever terminal is defined in flake.nix is auto-enabled
  "1password".enable = true;
  gaming.enable = true;
  syncthing.enable = true;

  # Root persistance - rollback
  # Restores "/" on each boot to root-blank btrfs snapshot
  # (partial persistance is enabled regardless of this being enabled - persist.nix)
  rollback.enable = false;


  ##########################################################
  # System-Specific Packages / Variables
  ##########################################################
  environment = {
    systemPackages = with pkgs; [
    # Codecs
      ffmpeg

    # Email
      thunderbird             # Email client
      protonmail-bridge-gui   # GUI bridge for Thunderbird

    # Framework Hardware
      dmidecode               # Firmware | 'dmidecode -s bios-version'
      framework-tool          # Swiss army knife for FWs
      fw-ectool               # ectool
      iio-sensor-proxy        # Ambient light sensor | 'monitor-sensor'
      lshw                    # Firmware

    # Messaging
      discord                 # Discord

    # Monitoring
      amdgpu_top              # GPU stats
      nvtopPackages.amd       # GPU stats
      powertop                # Power stats
      zenmonitor              # CPU stats

    # Multimedia
      mpv                     # Media player
      plex-media-player       # Plex player
      spicetify-cli           # Spotify theming
      spotify                 # Music

    # Notes
      obsidian                # Markdown notes

    # VPN
      protonvpn-gui           # VPN client
    ];
  };

  programs.gamescope.args = [
    #"--adaptive-sync"
    #"--borderless"
    #"--expose-wayland"
    #"--filter fsr"
    "--fullscreen"
    "--framerate-limit 60"
    #"--hdr-enabled"
    # Toggling doesn't work using --mangoapp
    #"--mangoapp"
    "--nested-height 1504"
    "--nested-refresh 60"
    "--nested-width 2256"
    #"--prefer-vk-device \"1002:15bf\""
    "--rt"
  ];


  ##########################################################
  # Home Manager Options
  ##########################################################
  home-manager.users.${vars.user} = { config, lib, ... }: {
    dconf.settings = {
      "org/gnome/shell" = {
        enabled-extensions = [
          "Battery-Health-Charging@maniacx.github.com"
        ];
      };
      "org/gnome/shell/extensions/Battery-Health-Charging" = {
        amend-power-indicator = true;
        bal-end-threshold = 85;
        charging-mode = "bal";
        current-bal-end-threshold = 85;
        indicator-position = 4;
        show-system-indicator = false;
      };
    };

    home.packages = with pkgs.gnomeExtensions; [
      battery-health-charging
    ];

    # https://github.com/ceiphr/ee-framework-presets
    services.easyeffects = {
      enable = true;
      preset = "philonmetal";
    };

    xdg.configFile = {
      # Minimize on-start not yet integrated
      #"autostart/protonvpn-app.desktop".source = config.lib.file.mkOutOfStoreSymlink "/run/current-system/sw/share/applications/protonvpn-app.desktop";
      "autostart/easyeffects-service.desktop".text = ''
        [Desktop Entry]
        Name=Easy Effects
        Comment=Easy Effects Service
        Exec=easyeffects --gapplication-service
        Icon=com.github.wwmm.easyeffects
        StartupNotify=false
        Terminal=false
        Type=Application
      '';
      "easyeffects/output/philonmetal.json".source = ./philonmetal.json;
    };
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
    enableAllFirmware = true;
    
    # amdgpu / wifi
    firmware = [ pkgs.linux-firmware ];

    # For kernels < 6.7
    framework.amd-7040.preventWakeOnAC = false;

    # Allow 5GHz wifi
    wirelessRegulatoryDatabase = true;

    opengl = {
      enable = true;
      # DRI are Mesa drivers
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        amdvlk
        libvdpau-va-gl
        rocmPackages.clr.icd
        vaapiVdpau
      ];
      extraPackages32 = with pkgs.driversi686Linux; [
        amdvlk
        libvdpau-va-gl
        vaapiVdpau
      ];
    };
  };

  # Auto-tune on startup
  powerManagement = {
    enable = true;
    # Auto-tuning
    powertop.enable = true;
  };

  services = {
    # CPU power mode
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };

    # Firmware updater
    fwupd = {
      enable = true;
      # v1.9.7 is required to downgrade the fingerprint sensor firmware
      # https://github.com/NixOS/nixos-hardware/tree/master/framework/13-inch/7040-amd
      # https://knowledgebase.frame.work/en_us/updating-fingerprint-reader-firmware-on-linux-for-13th-gen-and-amd-ryzen-7040-series-laptops-HJrvxv_za
      /*
      package = (import (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/bb2009ca185d97813e75736c2b8d1d8bb81bde05.tar.gz";
        sha256 = "sha256:003qcrsq5g5lggfrpq31gcvj82lb065xvr7bpfa8ddsw8x4dnysk";
      }) { inherit (pkgs) system; }).fwupd;
      */
    };

    # Lid close, power button, and idle actions
    logind = {
      lidSwitch = "suspend";
      powerKey = "suspend-then-hibernate";
      extraConfig = ''
        HandleLidSwitch=suspend
        IdleAction=suspend
        IdleActionSec=10m
      '';
    };

    # Temperature management
    thermald.enable = true;

    # GPU mode changes when plugged into power
    udev.extraRules = ''
      SUBSYSTEM=="power_supply" RUN+="${gpuPower}/bin/dpm_level.sh %E{POWER_SUPPLY_ONLINE}"
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
  # Boot / Encryption
  ##########################################################
  boot = {
    plymouth = {
      enable = true;
      theme = "framework";
      themePackages = [ plymouth-fw ];
    };

    # Allow 5GHz wifi & framework-laptop-kmod
    extraModprobeConfig = ''
      options cfg80211 ieee80211_regdom="US"
    '';

    # Zenpower uses same PCI device as k10temp, so disabling k10temp
    blacklistedKernelModules = [ "k10temp" ];
    kernelModules = [
      "framework_laptop"
      "zenpower"
    ];
    extraModulePackages = with config.boot.kernelPackages; [
      framework-laptop-kmod
      zenpower
    ];

    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      # Mask gpe0B ACPI interrupts
      "acpi_mask_gpe=0x0B"
      # Fixes VP9/VAAPI video glitches
      "amd_iommu=off"
      # Enables power profiles daemon control
      "amd_pstate=active"
      # Disable IPv6 stack
      "ipv6.disable=1"
      "quiet"
    ];
   
    kernelPatches = [
      {
        name = "fw-amd-ec";
        patch = ./fw-amd-ec.patch;
      }
      {
        name = "fw-amd-usbpd";
        patch = ./fw-amd-usbpd.patch;
      }
    ];

    supportedFilesystems = [ "btrfs" ];

    initrd = {
      availableKernelModules = [ "cryptd" ];
      kernelModules = [ "amdgpu" ];
      # Required for Plymouth (password prompt)
      systemd.enable = true;

      luks.devices = {
        "cryptkey" = { device = "/dev/disk/by-partlabel/key"; };

        "cryptroot" = {
          # SSD trim
          allowDiscards = true;
          # Faster SSD performance
          bypassWorkqueues = true;
          device = "/dev/disk/by-partlabel/root";
          keyFile = "/dev/mapper/cryptkey";
          keyFileSize = 8192;
        };
      };
    };

    loader = {
      timeout = 1;

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };

      grub = {
        enable = false;
        configurationLimit = 5;
        device = "nodev";
        efiSupport = true;
        enableCryptodisk = true;
        memtest86.enable = true;
        useOSProber = true;
        users.${vars.user}.hashedPasswordFile = "/persist/etc/users/grub";
      };

      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        # Console resolution
        consoleMode = "auto";
        editor = false;
        memtest86.enable = true;
      };
    };
  };


  ##########################################################
  # Network
  ##########################################################
  # 6.7 introduced a wifi disconnection bug - still occurring in 6.8.2?
  # I haven't experienced this yet - maybe present in wpa_supplicant and not iwd?
  # On resume, run: sudo rmmod mt7921e && sudo modprobe mt7921e
  # https://community.frame.work/t/framework-13-amd-issues-with-wireless-after-resume/44597
  networking = {
    enableIPv6 = false;
    hostName = host.hostName;
    # Interfaces not needed with NetworkManager enabled
    # USBC Ethernet right-rear port
    #interfaces.enp195s0f3u1c2.useDHCP = lib.mkDefault true;
    # USBC Ethernet left-rear port
    #interfaces.enp195s0f4u1c2.useDHCP = lib.mkDefault true;

    networkmanager = {
      enable = true;
      wifi = {
        # iwd provides more stability/throughput on AMD FW models
        backend = "iwd";
        macAddress = "stable-ssid";
        powersave = false;
      };
    };
  };


  ##########################################################
  # Filesystems
  ##########################################################
  fileSystems = {
    "/" = {
      device = "/dev/mapper/cryptroot";
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
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [
        "compress=zstd"
        "subvol=home"
      ];
    };

    "/nix" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [
        "compress=zstd"
        "noatime"
        "subvol=nix"
      ];
    };

    "/persist" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      neededForBoot = true;
      options = [
        "compress=zstd"
        "noatime"
        "subvol=persist"
      ];
    };

    "/var/log" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      neededForBoot = true;
      options = [
        "compress=zstd"
        "noatime"
        "subvol=log"
      ];
    };
  };
}

