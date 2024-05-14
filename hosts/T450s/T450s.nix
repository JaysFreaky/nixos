{ config, host, lib, pkgs, vars, ... }:

{
  imports = lib.optional (builtins.pathExists ./swap.nix) ./swap.nix;

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
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        # Imported through nixos-hardware/lenovo/T450s from nixos-hardware/common/gpu/intel
      ];
      extraPackages32 = with pkgs.driversi686Linux; [
        intel-media-driver
        intel-vaapi-driver
      ];
    };
  };


  ##########################################################
  # Boot / Encryption
  ##########################################################
  boot = {
    plymouth = {
      enable = false;
      theme = "nixos-bgrt";
      themePackages = [ pkgs.nixos-bgrt-plymouth ];
    };

    kernelModules = [ ];
    extraModulePackages = [ ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "quiet"
    ];
    supportedFilesystems = [ "btrfs" ];

    initrd = {
      availableKernelModules = [ ];
      kernelModules = [ "nfs" ];
      # Required for Plymouth (password prompt)
      systemd.enable = true;
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
        enableCryptodisk = false;
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
  networking = {
    hostName = host.hostName;
    # Interfaces not needed with NetworkManager enabled
    networkmanager.enable = true;
  };


  ##########################################################
  # Filesystems
  ##########################################################
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-partlabel/root";
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
      device = "/dev/disk/by-partlabel/root";
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
      device = "/dev/disk/by-partlabel/root";
      fsType = "btrfs";
      options = [
        "compress=zstd"
        "noatime"
        "subvol=nix"
      ];
    };

    "/persist" = {
      device = "/dev/disk/by-partlabel/root";
      fsType = "btrfs";
      neededForBoot = true;
      options = [
        "compress=zstd"
        "noatime"
        "subvol=persist"
      ];
    };

    "/var/log" = {
      device = "/dev/disk/by-partlabel/root";
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
