{ config, host, lib, modulesPath, pkgs, vars, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  ##########################################################
  # Custom Options
  ##########################################################
  # Desktop - gnome, hyprland
  gnome.enable = true;

  # Hardware - audio (on by default), bluetooth, fp_reader

  # Programs / Features - alacritty, flatpak, gaming, kitty, syncthing
  # Whichever terminal is defined in flake.nix is auto-enabled

  # Root persistance - rollback
  # Restores "/" on each boot to root-blank btrfs snapshot
  # (partial persistance is enabled regardless of this being enabled - persist.nix)
  rollback.enable = false;


  ##########################################################
  # System-Specific Packages / Variables
  ##########################################################
  environment = {
    systemPackages = with pkgs; [
    # Category
      #appName
    ];

    variables = {
      # Set Firefox to use iGPU for video codecs - run 'stat /dev/dri/*' to list GPUs
      MOZ_DRM_DEVICE = "/dev/dri/card0";
    };
  };


  ##########################################################
  # Home Manager Options
  ##########################################################


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        # Done in nixos-hardware t450s - not needed?
        #intel-media-driver
        #intel-vaapi-driver
        #vaapiIntel
      ];
      extraPackages32 = [ pkgs.driversi686Linux.intel-media-driver ];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";


  ##########################################################
  # Boot / Encryption
  ##########################################################
  boot = {
    plymouth = {
      enable = true;
      theme = "nixos-bgrt";
      themePackages = [ pkgs.nixos-bgrt-plymouth ];
    };

    kernel.sysctl = {
      # Disable IPv6
      "net.ipv6.conf.all.disable_ipv6" = true;
      # Prioritize swap for hibernation only
      "vm.swappiness" = lib.mkDefault 0;
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "quiet" ];
    resumeDevice = "/dev/mapper/cryptswap";
    supportedFilesystems = [ "btrfs" ];

    initrd = {
      availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "sd_mod" "rtsx_pci_sdmmc" "usb_storage" "aesni_intel" "cryptd" ];
      kernelModules = [ "dm-snapshot" "nfs" ];
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
        devices = [ "nodev" ];
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
  networking = with host; {
    # Currently broken, so using boot.kernel.sysctl workaround
    enableIPv6 = false;
    hostName = hostName;
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;

    interfaces = {
      enp0s25.useDHCP = lib.mkDefault true;
      wlp3s0.useDHCP = lib.mkDefault true;
    };
  };


  ##########################################################
  # Filesystems / Swap
  ##########################################################
  fileSystems = {
    "/" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=root" "compress=zstd" "noatime" ];
    };

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

    "/nas" = {
      device = "10.0.10.10:/mnt/user";
      fsType = "nfs";
      options = [ "noauto" "x-systemd.automount" "x-systemd.device-timeout=5s" "x-systemd.idle-timeout=600" "x-systemd.mount-timeout=5s" ];
    };
  };

  swapDevices = [ { device = "/dev/mapper/cryptswap"; } ];
}
