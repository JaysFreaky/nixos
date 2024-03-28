{ config, host, lib, modulesPath, pkgs, vars, ... }:
let
  scale = 1.25;
in {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];


  ##########################################################
  # Custom Options
  ##########################################################
  # Desktop - gnome, hyprland
  hyprland.enable = true;

  # Hardware - audio (on by default), bluetooth, fp_reader

  # Programs / Features - alacritty, flatpak, gaming, kitty, syncthing
  # Whichever terminal is defined in flake.nix is auto-enabled

  # Root persistance - tmpfs or snapshot & rollback
  # Can enable snapshot without rollback for a standard BTRFS install
  # (persistance is enabled regardless of these being enabled)
  snapshot.enable = true;
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
      MOZ_DRM_DEVICE = "/dev/dri/card0";
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


  ##########################################################
  # Network
  ##########################################################


  ##########################################################
  # Filesystems / Swap
  ##########################################################
}

