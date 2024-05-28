{ config, host, lib, pkgs, vars, ... }:
#let
  # Generate GPU path for Firefox environment variable
  #gpuCard = "$(stat /dev/dri/* | grep card | cut -d':' -f 2 | tr -d ' ')";
#in
{
  imports = lib.optional (builtins.pathExists ./swap.nix) ./swap.nix;

  ##########################################################
  # Custom Options
  ##########################################################
  # Desktop - gnome, hyprland
  #gnome.enable = true;

  # Hardware - audio (on by default), bluetooth, fp_reader
  #bluetooth.enable = true;

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
      #zenmonitor             # CPU stats
    ];

    variables = {
      # Set Firefox to use iGPU for video codecs
      #MOZ_DRM_DEVICE = gpuCard;
    };
  };

  jovian = {
    decky-loader.enable = true;
    devices.steamdeck.enable = true;

    steam = {
      enable = true;
      # Big mode
      autoStart = true;
      # Switch to desktop
      desktopSession = "plasma";
      user = ${vars.user};
    };
  };

  programs.gamescope.args = [
    #"--adaptive-sync"
    #"--borderless"
    #"--expose-wayland"
    #"--filter fsr"
    "--fullscreen"
    #"--framerate-limit 144"
    #"--hdr-enabled"
    # Toggling doesn't work using --mangoapp
    #"--mangoapp"
    #"--nested-height 1440"
    #"--nested-refresh 144"
    #"--nested-width 2560"
    #"--prefer-vk-device \"1002:73a5\""
    "--rt"
  ];

  services.desktopManager.plasma6.enable = true;


  ##########################################################
  # Home Manager Options
  ##########################################################


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
    opengl = {
      enable = true;
      # DRI are Mesa drivers
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        #amdvlk
        #libvdpau-va-gl
        #rocmPackages.clr.icd
        #vaapiVdpau
      ];
      extraPackages32 = with pkgs.driversi686Linux; [
        #amdvlk
        #libvdpau-va-gl
        #vaapiVdpau
      ];
    };
  };


  ##########################################################
  # Boot / Encryption
  ##########################################################
  boot = {
    # Zenpower uses same PCI device as k10temp, so disabling k10temp
    #blacklistedKernelModules = [ "k10temp" ];
    kernelModules = [
      #"zenpower"
    ];
    #extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      #"amd_pstate=active"
      # Adjust GPU clocks/voltages - https://wiki.archlinux.org/title/AMDGPU#Boot_parameter
      #"amdgpu.ppfeaturemask=0xffffffff"
      #"quiet"
    ];
    supportedFilesystems = [ "btrfs" ];

    initrd = {
      availableKernelModules = [ ];
      kernelModules = [
        #"amdgpu"
      ];
      # Required for Plymouth (password prompt)
      systemd.enable = true;
    };

    loader = {
      timeout = 1;

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };

      grub = {
        enable = false;
        configurationLimit = 5;
        device = "nodev";
        efiSupport = true;
        enableCryptodisk = false;
        memtest86.enable = true;
        #theme = "pkgs.sleek-grub-theme.override { withStyle = "dark"; }";
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

