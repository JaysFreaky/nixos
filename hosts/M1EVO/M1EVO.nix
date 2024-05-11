{ config, host, lib, pkgs, vars, ... }:
let
  scale = 1.25;
in {
  imports = lib.optional (builtins.pathExists ./swap.nix) ./swap.nix;

  ##########################################################
  # Custom Options
  ##########################################################
  # Desktop - gnome, hyprland
  hyprland.enable = true;

  # Hardware - audio (on by default), bluetooth, fp_reader

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
    # Monitoring
      amdgpu_top              # GPU stats
      nvtopPackages.amd       # GPU stats
      zenmonitor              # CPU stats
    ];

    variables = {
      # Set Firefox to use GPU for video codecs - run 'stat /dev/dri/*' to list GPUs
      # Might need to set this as a package override extraProfile
      MOZ_DRM_DEVICE = "/dev/dri/card1";
    };
  };

  programs.gamescope.args = [
    "--adaptive-sync"
    #"--borderless"
    #"--expose-wayland"
    "--filter fsr"
    "--fullscreen"
    #"--framerate-limit 144"
    "--hdr-enabled"
    # Toggling doesn't work using --mangoapp
    #"--mangoapp"
    "--nested-height 1440"
    "--nested-refresh 144"
    "--nested-width 2560"
    #"--prefer-vk-device \"10de:2206\""
    "--rt"
  ];


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
    opengl = {
      enable = true;
      # dri are Mesa/Vulkan drivers
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

    openrazer = {
      enable = true;
      users = [ "${vars.user}" ];
    };
  };

  services.hardware.openrgb.enable = true;


  ##########################################################
  # Boot / Encryption
  ##########################################################
  boot = {
    plymouth = {
      enable = false;
      theme = "nixos-bgrt";
      themePackages = [ pkgs.nixos-bgrt-plymouth ];
    };

    # Zenpower uses same PCI device as k10temp, so disabling k10temp
    blacklistedKernelModules = [ "k10temp" ];
    kernelModules = [
      "openrazer"
      "zenpower"
    ];
    extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      #"quiet"
    ];
    supportedFilesystems = [ "btrfs" ];

    initrd = {
      availableKernelModules = [ "cryptd" ];
      kernelModules = [
        "amdgpu"
        "nfs"
      ];

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
  networking = {
    hostName = host.hostName;
    networkmanager.enable = true;
    # Interfaces not needed with NetworkManager enabled
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

    "/media/steam" = {
      device = "/dev/nvme1n1p1";
      fsType = "ext4";
      options = [
        "noatime"
        "x-systemd.automount"
        "x-systemd.device-timeout=5s"
        #"x-systemd.idle-timeout=600"
        "x-systemd.mount-timeout=5s"
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

