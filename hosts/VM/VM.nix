{ lib, pkgs, vars, ... }: {
  imports = lib.optional (builtins.pathExists ./swap.nix) ./swap.nix;

  ##########################################################
  # Custom Options
  ##########################################################
  # Desktop - gnome, hyprland, kde
  gnome.enable = true;

  # Hardware - amdgpu, audio (on by default), bluetooth, fp_reader, nvidia
  audio.enable = false;

  # Programs / Features - 1password, alacritty, flatpak, gaming, kitty, syncthing, wezterm
  # Whichever terminal is defined in flake.nix is auto-enabled in hosts/common.nix, but can enable more


  ##########################################################
  # System-Specific Packages / Variables
  ##########################################################
  environment.systemPackages = with pkgs; [ ];

  services.displayManager.autoLogin = {
    enable = lib.mkForce true;
    user = "${vars.user}";
  };


  ##########################################################
  # Home Manager Options
  ##########################################################


  ##########################################################
  # Hardware
  ##########################################################
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiIntel
    ];
    extraPackages32 = with pkgs.driversi686Linux; [
      intel-media-driver
    ];
  };


  ##########################################################
  # Boot / Encryption
  ##########################################################
  boot = {
    initrd = {
      availableKernelModules = [ ];
      kernelModules = [ ];
      # Required for Plymouth (password prompt)
      systemd.enable = true;
    };

    kernelModules = [ ];
    extraModulePackages = [ ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "quiet"
      "splash"
    ];

    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
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

    supportedFilesystems = [ "btrfs" ];
  };


  ##########################################################
  # Network
  ##########################################################
  networking = {
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
  };

}
