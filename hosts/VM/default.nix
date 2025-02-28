{
  lib,
  pkgs,
  myUser,
  ...
}: {
  imports = [
    ./filesystems.nix
    ./hardware-configuration.nix
  ];

  ##########################################################
  # Custom Options
  ##########################################################
  myOptions = {
    desktops = {
      gnome.enable = true;
      kde.enable = false;
    };

    hardware.audio.enable = false;

    # "1password", flatpak, kitty, wezterm
  };


  ##########################################################
  # System Packages / Variables
  ##########################################################
  environment = {
    systemPackages = [ ];
    # Set Firefox to use GPU for video codecs
    variables.MOZ_DRM_DEVICE = "$(stat /dev/dri/* | grep card | cut -d':' -f 2 | tr -d ' ')";
  };

  # Bypass occasional login screen freeze
  services.displayManager.autoLogin = {
    enable = lib.mkForce true;
    user = myUser;
  };

  system.stateVersion = "24.11";


  ##########################################################
  # Home Manager
  ##########################################################
  home-manager.users.${myUser} = {
    home.stateVersion = "24.11";
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware.graphics = {
    extraPackages = builtins.attrValues {
      inherit (pkgs)
        intel-compute-runtime
        intel-media-driver
        intel-vaapi-driver
        libvpl
        vpl-gpu-rt
      ;
    };
    extraPackages32 = builtins.attrValues {
      inherit (pkgs.driversi686Linux)
        intel-media-driver
        intel-vaapi-driver
      ;
    };
  };


  ##########################################################
  # Boot
  ##########################################################
  boot = {
    initrd.systemd.enable = true;

    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "quiet" ];

    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
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
}
