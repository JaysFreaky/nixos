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
    echo $DRM_PERF_LEVEL > /sys/class/drm/card0/device/power_dpm_force_performance_level
  '';
in {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

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

  # Root persistance - tmpfs or snapshot & rollback
  # Can enable snapshot without rollback for a standard BTRFS install
  # (persistance is enabled regardless of these being enabled)
  tmpfs.enable = true;


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
      MOZ_DRM_DEVICE = "/dev/dri/card0";
    };
  };


  ##########################################################
  # Home Manager Options
  ##########################################################
  home-manager.users.${vars.user} = { lib, ... }: {
    dconf.settings = {
      "com/github/wwmm/easyeffects" = {
        last-used-output-preset = "philonmetal";
      };
      "org/gnome/shell" = {
        enabled-extensions = [
          #"Battery-Health-Charging@maniacx.github.com"
          "easyeffects-preset-selector"
          #"proton-vpn@fthx"
          #"proton-bridge@fthx"
        ];
      };
      #"org/gnome/shell/extensions/Battery-Health-Charging" = {
      #  amend-power-indicator = true;
      #  icon-style-type = 1;
      #};
    };

    home.packages = with pkgs.gnomeExtensions; [
      #battery-health-charging
      easyeffects-preset-selector
      #proton-bridge-button
      #proton-vpn-button
    ];

    # https://github.com/ceiphr/ee-framework-presets
    services.easyeffects = {
      enable = true;
      preset = "philonmetal";
    };
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
    enableAllFirmware = true;
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

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
        mesa
        rocmPackages.clr
        vaapiVdpau
      ];
      extraPackages32 = with pkgs; [
        driversi686Linux.amdvlk
        driversi686Linux.libvdpau-va-gl
        driversi686Linux.mesa
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

  # Yubikey login/sudo
/*security.pam.yubico = {
    enable = true;
    debug = false;
    mode = "challenge-response";
  };*/


  services = {
    # Disable fprint reader - testing fp_reader.enable module
    #fprintd.enable = lib.mkForce false;

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

    xserver.videoDrivers = [ "amdgpu" "modesetting" ];

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
    };

    # GPU performance - power_dpm_force_performance_level is auto by default
    udev.extraRules = ''
      SUBSYSTEM=="power_supply" RUN+="${set_dpm}/bin/dpm.sh %E{POWER_SUPPLY_ONLINE}"
    '';
      #SUBSYSTEM=="power_supply" RUN+="${writeShellScriptBin "set_dpm_perf_level" (builtins.readFile ./set_dpm_perf_level.sh) %E{POWER_SUPPLY_ONLINE}}"
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
      theme = "nixos-bgrt";
      themePackages = [ pkgs.nixos-bgrt-plymouth ];
    };

    extraModprobeConfig = ''
      options cfg80211 ieee80211_regdom="US"
    '';

    kernel.sysctl = {
      # Disable IPv6
      "net.ipv6.conf.all.disable_ipv6" = true;
      # Prioritize swap for hibernation only
      "vm.swappiness" = lib.mkDefault 0;
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = with config.boot.kernelPackages; [ zenpower ];

    # Previous stable kernel
    #kernelPackages = pkgs.linuxPackages_6_1;
    kernelPackages = pkgs.linuxPackages_latest;

    # amd_iommu - fixes VP9/VAAPI video glitches
    # amd_pstate - enables power profiles daemon
    # amdgpu.sg_display - fixes white screen / glitches
    # rtc_cmos.use_acpi_alarm - fixes waking after 5 minutes - remove at kernel 6.8?
    kernelParams = [ "amd_iommu=off" "amd_pstate=active" "amdgpu.sg_display=0" "mem_sleep_default=deep" "quiet" "rtc_cmos.use_acpi_alarm=1" ];

    resumeDevice = "/dev/mapper/cryptswap";
    supportedFilesystems = [ "btrfs" ];

    initrd = {
      availableKernelModules = [ "cryptd" "nvme" "sd_mod" "thunderbolt" "usb_storage" "xhci_pci" ];
      kernelModules = [ "amdgpu" ];
      # Systemd support for booting
      systemd.enable = true;

      luks.devices = {
        "cryptkey" = { device = "/dev/disk/by-partlabel/cryptkey"; };

        "cryptswap" = {
          device = "/dev/disk/by-partlabel/cryptswap";
          keyFile = "/dev/mapper/cryptkey";
          keyFileSize = 8192;
        };

        "cryptroot" = {
          # SSD trim
          allowDiscards = true;
          # Faster SSD performance
          bypassWorkqueues = true;
          device = "/dev/disk/by-partlabel/cryptroot";
          #fallbackToPassword = true;
          keyFile = "/dev/mapper/cryptkey";
          keyFileSize = 8192;
          #keyFileTimeout = 5;
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
      };
    };
  };


  ##########################################################
  # Network
  ##########################################################
  # 6.7 introduced a wifi disconnection bug: https://community.frame.work/t/framework-13-amd-issues-with-wireless-after-resume/44597
  # on resume, run: sudo rmmod mt7921e && sudo modprobe mt7921e
  networking = with host; {
    # Currently broken, so using boot.kernel.sysctl workaround
    enableIPv6 = false;
    hostName = hostName;
    useDHCP = lib.mkDefault true;

    firewall = {
      enable = true;
      #allowedTCPPorts = [ 80 443 ];
      #allowedUDPPorts = [ 53 ];
    };

    interfaces = {
      wlp1s0.useDHCP = lib.mkDefault true;
    };

    # Static DNS
    #nameservers = [ ];

    networkmanager = {
      enable = true;

      # Use static DNS from above instead of DHCP
      #dns = none;

      # Faster wifi on AMD
      wifi.backend = "iwd";
      wifi.powersave = false;
    };
  };


  ##########################################################
  # Filesystems / Swap
  ##########################################################
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-partlabel/boot";
      fsType = "vfat";
    };

    "/home" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=home" "compress=zstd" ];
    };

    "/nix" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=nix" "compress=zstd" "noatime" ];
    };

    "/persist" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=persist" "compress=zstd" "noatime"];
      neededForBoot = true;
    };

    "/var/log" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=log" "compress=zstd" "noatime"];
      neededForBoot = true;
    };
  };

  swapDevices = [ { device = "/dev/mapper/cryptswap"; } ];
}

