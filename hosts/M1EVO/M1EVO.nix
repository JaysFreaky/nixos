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
      #radeontop          # GPU stats
      zenmonitor          # CPU stats
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

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        #amdvlk
        #libvdpau-va-gl
        #mesa
        #rocmPackages.clr
        #vaapiVdpau
      ];
      extraPackages32 = with pkgs; [
        #driversi686Linux.amdvlk
        #driversi686Linux.libvdpau-va-gl
        #driversi686Linux.mesa
        #driversi686Linux.vaapiVdpau
      ];
    };

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
    plymouth = {
      enable = false;
      theme = "nixos-bgrt";
      themePackages = [ pkgs.nixos-bgrt-plymouth ];
    };

    kernelModules = [ "kvm-amd" ];
    extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      #"quiet"
    ];
    supportedFilesystems = [ "btrfs" ];

    initrd = {
      availableKernelModules = [
        "ahci"
        "cryptd"
        "nvme"
        "sd_mod"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];
      kernelModules = [
        #"amdgpu"
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
  networking = with host; {
    hostName = hostName;
    networkmanager.enable = true;
    networkmanager.unmanaged = [ "wlp6s0" ];

    # Interfaces not needed with NetworkManager enabled
    #interfaces.enp7s0.useDHCP = lib.mkDefault true;
    #interfaces.wlp6s0.useDHCP = lib.mkForce false;
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

    "/home/${vars.user}/Games/Steam" = {
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

