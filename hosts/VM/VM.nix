{ config, host, lib, modulesPath, pkgs, vars, ... }:
with lib;
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  ##########################################################
  # Custom Options
  ##########################################################
  # Desktop - gnome, hyprland
  gnome.enable = true;

  # Hardware - audio (on by default), bluetooth, fp_reader
  audio.enable = false;

  # Programs / Features - alacritty, flatpak, gaming, kitty, syncthing
  # Whichever terminal is defined in flake.nix is auto-enabled
  #flatpak.enable = true;

  # Root persistance - tmpfs or snapshot & rollback
  # Can enable snapshot without rollback for a standard BTRFS install
  # (persistance is enabled regardless of these being enabled)
  tmpfs.enable = true;


  ##########################################################
  # System-Specific Packages / Variables
  ##########################################################
  environment = {
    systemPackages = with pkgs; [
    # Category
      #appName
    ];
  };

  services.xserver.displayManager.autoLogin = {
    enable = mkForce true;
    user = "${vars.user}";
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
        intel-media-driver
        intel-vaapi-driver
        vaapiIntel
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
      availableKernelModules = [ "xhci_pci" "ahci" "virtio_pci" "sr_mod" "virtio_blk" "aesni_intel" "cryptd" ];
      kernelModules = [ ];
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
    useDHCP = lib.mkDefault true;

    interfaces = {
      enp2s0.useDHCP = lib.mkDefault true;
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

