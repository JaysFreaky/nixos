{ config, host, lib, modulesPath, pkgs, vars, ... }:
let
  scale = 1.25;
in {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ] ++
    lib.optional (builtins.pathExists ./swap.nix) ./swap.nix;

  ##########################################################
  # Custom Options
  ##########################################################
  # Desktop - gnome, hyprland
  hyprland.enable = true;

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
  home-manager.users.${vars.user} = {
    wayland.windowManager.hyprland.settings = {
      # hyprctl monitors all
      # name,resolution@htz,position,scale
      monitor = [
        #",preferred,auto,auto"
        #"eDP-1,2560x1440@144,0x0,${toString scale}"
      ];
    };
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    openrazer = {
      enable = true;
      users = [ "${vars.user}" ];
    };
  };

  services.hardware.openrgb.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";


  ##########################################################
  # Boot / Encryption
  ##########################################################
  boot = {
    kernel.sysctl = {
      # Disable IPv6
      "net.ipv6.conf.all.disable_ipv6" = true;
      # Prioritize swap for hibernation only
      "vm.swappiness" = lib.mkDefault 0;
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ ];
    supportedFilesystems = [ "btrfs" ];

    initrd = {
      availableKernelModules = [
        "ahci"
        "nvme"
        "sd_mod"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];
      kernelModules = [ ];
      # Systemd support for booting
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
  networking = with host; {
    # Currently broken, so using boot.kernel.sysctl workaround
    enableIPv6 = false;
    hostName = hostName;
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;

    interfaces = {
      enp7s0.useDHCP = lib.mkDefault true;
      wlp6s0.useDHCP = false;
    };
  };


  ##########################################################
  # Filesystems
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

    "/home/${vars.user}/Games/Steam" = {
      device = "/dev/nvme1n1p1";
      fsType = "ext4";
      options = [ "noatime" "x-systemd.automount" "x-systemd.device-timeout=5s" "x-systemd.idle-timeout=600" "x-systemd.mount-timeout=5s" ];
    };

    "/nas" = {
      device = "10.0.10.10:/mnt/user";
      fsType = "nfs";
      options = [ "noauto" "x-systemd.automount" "x-systemd.device-timeout=5s" "x-systemd.idle-timeout=600" "x-systemd.mount-timeout=5s" ];
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
}

