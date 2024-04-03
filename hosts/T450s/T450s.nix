{ config, host, lib, modulesPath, pkgs, vars, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ] ++
    lib.optional (builtins.pathExists ./swap.nix) ./swap.nix;

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
      MOZ_DRM_DEVICE = "/dev/dri/card1";
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
        # Imported through nixos-hardware/lenovo/T450s from nixos-hardware/common/gpu/intel
      ];
      extraPackages32 = with pkgs; [
        driversi686Linux.intel-media-driver
        driversi686Linux.intel-vaapi-driver
      ];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";


  ##########################################################
  # Boot / Encryption
  ##########################################################
  boot = {
    plymouth = {
      enable = false;
      theme = "nixos-bgrt";
      themePackages = [ pkgs.nixos-bgrt-plymouth ];
    };

    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "quiet"
    ];
    supportedFilesystems = [ "btrfs" ];

    initrd = {
      availableKernelModules = [
        "aesni_intel"
        "ahci"
        "cryptd"
        "ehci_pci"
        "rtsx_pci_sdmmc"
        "sd_mod"
        "usb_storage"
        "xhci_pci"
      ];
      kernelModules = [ "nfs" ];

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
    enableIPv6 = false;
    hostName = hostName;
    networkmanager.enable = true;
    #useDHCP = lib.mkDefault true;

    interfaces = {
      # Ethernet adapter left-rear USB port
      enp0s20u3.useDHCP = lib.mkDefault true;

      enp0s25.useDHCP = lib.mkDefault true;
      wlp3s0.useDHCP = lib.mkDefault true;
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

    "/nas" = {
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
