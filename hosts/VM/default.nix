{ lib, pkgs, vars, ... }: {
  imports = [
    ./filesystems.nix
    ./hardware-configuration.nix
  ];

  ##########################################################
  # Custom Options
  ##########################################################
  myOptions = {
    desktops = {  # gnome, kde
      gnome.enable = true;
    };

    hardware = {  # audio
      audio.enable = false;
    };

    # "1password", alacritty, flatpak, kitty, syncthing, wezterm
  };


  ##########################################################
  # System Packages / Variables
  ##########################################################
  environment = {
    systemPackages = [ ];
    # Set Firefox to use GPU for video codecs
    variables.MOZ_DRM_DEVICE = "$(stat /dev/dri/* | grep card | cut -d':' -f 2 | tr -d ' ')";
  };

  services.displayManager.autoLogin = {
    enable = lib.mkForce true;
    user = "${vars.user}";
  };

  system.stateVersion = "24.11";


  ##########################################################
  # Home Manager
  ##########################################################
  home-manager.users.${vars.user} = {
    home.stateVersion = "24.11";
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware.graphics = {
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
  # Boot
  ##########################################################
  boot = {
    initrd = {
      availableKernelModules = [ ];
      kernelModules = [ ];
      systemd.enable = true;
    };

    kernelModules = [ ];
    extraModulePackages = [ ];
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
  networking.hostName = "VM";

}
