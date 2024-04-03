{ config, host, lib, modulesPath, pkgs, vars, ... }:
let
  set_dpm = pkgs.writeShellScriptBin "dpm.sh" ''
    #!/usr/bin/env bash

    # Default level
    DRM_PERF_LEVEL=low

    # Evaluate argument passed by udev
    if [ $1 -eq 1 ] ; then
      DRM_PERF_LEVEL=high
    else
      DRM_PERF_LEVEL=low
    fi

    # Set drm performance level
    echo $DRM_PERF_LEVEL > /sys/class/drm/card1/device/power_dpm_force_performance_level
  '';
in {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ] ++
    lib.optional (builtins.pathExists ./swap.nix) ./swap.nix;

  ##########################################################
  # Custom Options
  ##########################################################
  # Desktop - gnome, hyprland
  gnome.enable = true;

  # Hardware - audio (on by default), bluetooth, fp_reader
  bluetooth.enable = true;

  # Programs / Features - alacritty, flatpak, gaming, kitty, syncthing
  # Whichever terminal is defined in flake.nix is auto-enabled
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
      #thunderbird        # Email client
      #protonmail-bridge  # Allows Thunderbird to connect to Proton
      #protonmail-bridge-gui
      protonmail-desktop

    # Framework Hardware
      dmidecode           # Firmware | 'dmidecode -s bios-version'
      framework-tool      # Swiss army knife for FWs
      fw-ectool           # ectool
      iio-sensor-proxy    # Ambient light sensor | 'monitor-sensor'
      lshw                # Firmware
      radeontop           # GPU stats
      zenmonitor          # CPU stats

    # VPN
      protonvpn-gui       # VPN client
    ];

    variables = {
      # Set Firefox to use iGPU for video codecs - run 'stat /dev/dri/*' to list GPUs
      MOZ_DRM_DEVICE = "/dev/dri/card1";
    };
  };


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
      "easyeffects/output/philonmetal.json".source = ./philonmetal.json;
    };
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    enableAllFirmware = true;

    # For kernels older than 6.7
    #framework.amd-7040.preventWakeOnAC = true;

    # Ambient light sensor
    sensor.iio.enable = true;

    # Allow 5GHz wifi
    wirelessRegulatoryDatabase = true;

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        amdvlk
        libvdpau-va-gl
        #mesa
        rocmPackages.clr
        vaapiVdpau
      ];
      extraPackages32 = with pkgs; [
        driversi686Linux.amdvlk
        driversi686Linux.libvdpau-va-gl
        #driversi686Linux.mesa
        driversi686Linux.vaapiVdpau
      ];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Auto-tune on startup
  powerManagement = {
    # “ondemand” “powersave” “performance”
    cpuFreqGovernor = "ondemand";

    # Auto-tuning
    powertop.enable = true;
  };

  services = {
    # Firmware updater
    fwupd = {
      enable = true;

      /*
      # v1.9.7 is required to downgrade the fingerprint sensor firmware
      # https://github.com/NixOS/nixos-hardware/tree/master/framework/13-inch/7040-amd
      # https://knowledgebase.frame.work/en_us/updating-fingerprint-reader-firmware-on-linux-for-13th-gen-and-amd-ryzen-7040-series-laptops-HJrvxv_za
      package = (import (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/bb2009ca185d97813e75736c2b8d1d8bb81bde05.tar.gz";
        sha256 = "sha256:003qcrsq5g5lggfrpq31gcvj82lb065xvr7bpfa8ddsw8x4dnysk";
      }) { inherit (pkgs) system; }).fwupd;
      */
    };

    # Power management
    upower.enable = true;

    xserver.videoDrivers = [
      "amdgpu"
      "modesetting"
    ];

    # Suspend-then-hibernate everywhere
    logind = {
      lidSwitch = "suspend-then-hibernate";
      powerKey = "suspend-then-hibernate";
      extraConfig = ''
        IdleAction=suspend-then-hibernate
        IdleActionSec=15m
      '';
    };

    # Power profiles
    power-profiles-daemon.enable = true;

    # GPU performance - power_dpm_force_performance_level is auto by default
    udev.extraRules = ''
      SUBSYSTEM=="power_supply" RUN+="${set_dpm}/bin/dpm.sh %E{POWER_SUPPLY_ONLINE}"
    '';
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
      enable = false;
      theme = "nixos-bgrt";
      themePackages = [ pkgs.nixos-bgrt-plymouth ];
    };

    extraModprobeConfig = ''
      options cfg80211 ieee80211_regdom="US"
    '';

    kernelModules = [ "kvm-amd" ];
    extraModulePackages = with config.boot.kernelPackages; [
      framework-laptop-kmod
      zenpower
    ];

    # Previous stable kernel
    #kernelPackages = pkgs.linuxPackages_6_1;
    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      "amd_iommu=off"  # fixes VP9/VAAPI video glitches
      "amd_pstate=active"  # enables power profiles daemon
      "amdgpu.sg_display=0"  # fixes white screen / glitches
      "ipv6.disable=1"
      "mem_sleep_default=deep"  # hibernation
      #"quiet"
      "rtc_cmos.use_acpi_alarm=1"  # fixes waking after 5 minutes - remove at kernel 6.8?
    ];
   
    kernelPatches = [
      {
        name = "fw-amd-ec";
        patch = ./fw-amd-ec.patch;
      }
    ];

    supportedFilesystems = [ "btrfs" ];

    initrd = {
      availableKernelModules = [
        "cryptd"
        "nvme"
        "sd_mod"
        "thunderbolt"
        "usb_storage"
        "xhci_pci"
      ];
      kernelModules = [ "amdgpu" ];

      # Required for full Plymouth experience (password prompt)
      systemd.enable = true;

      luks.devices = {
        "cryptkey" = { device = "/dev/disk/by-partlabel/cryptkey"; };

        "cryptroot" = {
          # SSD trim
          allowDiscards = true;
          # Faster SSD performance
          bypassWorkqueues = true;
          device = "/dev/disk/by-partlabel/cryptroot";
          keyFile = "/dev/mapper/cryptkey";
          keyFileSize = 8192;
        };
      };
    };

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
        enableCryptodisk = true;
        useOSProber = true;
        users.${vars.user}.hashedPasswordFile = "/persist/etc/users/grub";
      };

      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        # Console resolution
        consoleMode = "auto";
        memtest86.enable = true;
      };
    };
  };


  ##########################################################
  # Network
  ##########################################################
  # 6.7 introduced a wifi disconnection bug: https://community.frame.work/t/framework-13-amd-issues-with-wireless-after-resume/44597
  # on resume, run: sudo rmmod mt7921e && sudo modprobe mt7921e
  networking = with host; {
    enableIPv6 = false;
    hostName = hostName;

    firewall = {
      enable = true;
      #allowedTCPPorts = [ ];
      #allowedUDPPorts = [ ];
    };

    # Interfaces not needed with NetworkManager enabled
    #interfaces.wlp1s0.useDHCP = lib.mkDefault true;
    #
    # Ethernet adapter left-rear USB port
    #interfaces.enp195s0f4u1c2.useDHCP = lib.mkDefault true;
    # Ethernet adapter right-rear USB port
    #interfaces.enp195s0f3u1c2.useDHCP = lib.mkDefault true;

    networkmanager = {
      enable = true;
      wifi = {
        # Faster wifi on AMD models
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

