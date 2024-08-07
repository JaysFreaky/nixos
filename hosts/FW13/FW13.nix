{ config, host, inputs, lib, pkgs, vars, ... }: let
  # Custom plymouth theme
  framework-plymouth = pkgs.callPackage ../../packages/framework-plymouth {};
  # Patch kernel to log usbpd instead of warn
  fw-usbpd-charger = pkgs.callPackage ./usbpd { kernel = config.boot.kernelPackages.kernel; };
in {
  imports = lib.optional (builtins.pathExists ./swap.nix) ./swap.nix;

  ##########################################################
  # Custom Options
  ##########################################################
  # Desktop - gnome, hyprland, kde
  gnome.enable = true;

  # Hardware - amdgpu, audio (on by default), bluetooth, fp_reader, nvidia
  amdgpu.enable = true;
  bluetooth.enable = true;

  # Programs / Features - 1password, alacritty, flatpak, gaming, kitty, syncthing, wezterm
  # Whichever terminal is defined in flake.nix is auto-enabled in hosts/common.nix, but can enable more
  "1password".enable = true;
  gaming.enable = true;
  syncthing.enable = true;
  wezterm.enable = true;


  ##########################################################
  # System-Specific Packages / Variables
  ##########################################################
  environment.systemPackages = with pkgs; [
    # Email
    protonmail-bridge-gui   # GUI bridge for Thunderbird
    thunderbird             # Email client

    # Framework Hardware
    dmidecode               # Firmware | 'dmidecode -s bios-version'
    framework-tool          # Swiss army knife for FWs
    fw-ectool               # Embedded controller | 'ectool'
    iio-sensor-proxy        # Ambient light sensor | 'monitor-sensor'
    lshw                    # Firmware
    sbctl                   # Secure boot key manager

    # Messaging
    discord                 # Discord

    # Monitoring
    powertop                # Power stats
    zenmonitor              # CPU stats

    # Multimedia
    mpv                     # Media player
    plex-media-player       # Plex player

    # Notes
    obsidian                # Markdown notes

    # Productivity
    libreoffice

    # VPN
    protonvpn-gui           # VPN client
  ];

  programs = {
    # lspci -nn | grep -i vga
    gamescope.args = [
      #"--prefer-vk-device \"1002:15bf\""
      "--fullscreen"
      #"--borderless"
    ];

    spicetify = let spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system}; in {
      enable = true;
      theme = spicePkgs.themes.text;
      colorScheme = "TokyoNightStorm";
      enabledExtensions = with spicePkgs.extensions; [
        fullAlbumDate
        hidePodcasts
        savePlaylists
        wikify
      ];
    };
  };


  ##########################################################
  # Home Manager Options
  ##########################################################
  home-manager.users.${vars.user} = { config, ... }: {
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

    # lspci -D | grep -i vga
    programs.mangohud.settings.pci_dev = "0:c1:00.0";

    # https://github.com/ceiphr/ee-framework-presets
    services.easyeffects = {
      enable = true;
      preset = "philonmetal";
    };

    # Workaround for easyeeffects preset not auto loading
      # https://github.com/nix-community/home-manager/issues/5185
    systemd.user.services.easyeffects = let
      eePkg = (config.services.easyeffects.package);
      eePreset = (config.services.easyeffects.preset);
    in {
      Service.ExecStartPost = [ "${lib.getExe eePkg} --load-preset ${eePreset}" ];
    };

    xdg.configFile = {
      "autostart/ProtonMailBridge.desktop".text = ''
        [Desktop Entry]
        Exec="/run/current-system/sw/bin/protonmail-bridge-gui" "--no-window"
        Name=ProtonMailBridge
        Type=Application
        X-GNOME-Autostart-enabled=true
      '';
      "easyeffects/output/philonmetal.json".source = ./philonmetal.json;
    };
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
    bluetooth.powerOnBoot = lib.mkForce false;

    enableAllFirmware = true;
    # Firmware updates for amdgpu/wifi
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
    fwupd.enable = true;
    # v1.9.7 is required to downgrade the fingerprint sensor firmware
      # https://github.com/NixOS/nixos-hardware/tree/master/framework/13-inch/7040-amd
      # https://knowledgebase.frame.work/en_us/updating-fingerprint-reader-firmware-on-linux-for-13th-gen-and-amd-ryzen-7040-series-laptops-HJrvxv_za
  /*fwupd.package = (import (builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/bb2009ca185d97813e75736c2b8d1d8bb81bde05.tar.gz";
      sha256 = "sha256:003qcrsq5g5lggfrpq31gcvj82lb065xvr7bpfa8ddsw8x4dnysk";
    }) { inherit (pkgs) system; }).fwupd;*/

    # Lid close, power button, and idle actions
    logind = {
      lidSwitch = "suspend";
      powerKey = "suspend-then-hibernate";
      extraConfig = ''
        IdleAction=suspend
        IdleActionSec=10m
      '';
    };

    # Temperature management
    thermald.enable = true;

    # GPU perfarmance adjusts when plugged into power - power_dpm_force_performance_level is auto by default
    udev.extraRules = let gpuPower = pkgs.writeShellScriptBin "dpm_level.sh" ''
      #!/usr/bin/env bash
      # Find persistant GPU path: readlink -f /sys/class/drm/card1/device
      GPU_DEVICE=/sys/devices/pci0000\:00/0000\:00\:08.1/0000\:c1\:00.0

      # Default level
      DPM_PERF_LEVEL=low
      # Evaluate argument passed by udev
      if [ $1 -eq 1 ] ; then
        DPM_PERF_LEVEL=high
      else
        DPM_PERF_LEVEL=low
      fi

      # Set performance level
      echo "$DPM_PERF_LEVEL" > "$GPU_DEVICE"/power_dpm_force_performance_level
    ''; in ''
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
    initrd = {
      availableKernelModules = [ "cryptd" ];
      kernelModules = [ ];
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
      # Required for Plymouth (password prompt)
      systemd.enable = true;
    };

    # Allow 5GHz wifi
    extraModprobeConfig = ''
      options cfg80211 ieee80211_regdom="US"
    '';
    # Zenpower uses same PCI device as k10temp, so disabling k10temp
    blacklistedKernelModules = [ "k10temp" ];
    kernelModules = [
      "framework_laptop"
      "zenpower"
    ];
    extraModulePackages = (with config.boot.kernelPackages; [
      cpupower
      framework-laptop-kmod
      zenpower
    ]) ++ [
      (fw-usbpd-charger.overrideAttrs (_: { patches = [ ./usbpd/usbpd_charger.patch ]; }))
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
        # Console resolution
        consoleMode = "auto";
        editor = false;
        memtest86.enable = if (config.boot.lanzaboote.enable) then lib.mkForce false else true;
      };
      timeout = 1;
    };

    plymouth = {
      enable = true;
      theme = "framework";
      themePackages = [ framework-plymouth ];
    };

    supportedFilesystems = [ "btrfs" ];
  };


  ##########################################################
  # Network
  ##########################################################
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

  # 6.7 introduced a wifi disconnect hibernation bug; seems resolved in 6.10, but will continue testing
    # https://community.frame.work/t/framework-13-amd-issues-with-wireless-after-resume/44597
  #powerManagement.resumeCommands = ''sudo rmmod mt7921e && sleep 5 && sudo modprobe mt7921e'';


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
