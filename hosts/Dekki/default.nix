{ lib, pkgs, vars, ... }: {
  imports = [
    ./filesystems.nix
    ./hardware-configuration.nix
  ];

  ##########################################################
  # Custom Options
  ##########################################################
  myOptions = {
    desktops = {    # gnome, hyprland, kde
      gnome.enable = true;
    };

    hardware = {    # amdgpu, audio, bluetooth, fp_reader, nvidia
      #amdgpu.enable = true;
      #bluetooth.enable = true;
    };

    # "1password", alacritty, flatpak, gaming, kitty, syncthing, wezterm
    #gaming.enable = true;
  };


  ##########################################################
  # System Packages / Variables
  ##########################################################
  environment.systemPackages = with pkgs; [
    # Monitoring
      amdgpu_top              # GPU stats
      nvtopPackages.amd       # GPU stats
  ];

  jovian = {
    decky-loader.enable = true;
    devices.steamdeck.enable = true;

    steam = {
      # Steam Deck UI
      enable = true;
      # Start in Steam UI
      autoStart = true;
      # Switch to desktop - Use 'gamescope-wayland' for no desktop
      desktopSession = "gnome";
      user = "${vars.user}";
    };
  };

  services.xserver.displayManager.gdm.enable = lib.mkForce false;


  ##########################################################
  # Home Manager
  ##########################################################
  home-manager.users.${vars.user} = { config, lib, ... }: rec {
    dconf.settings = {
      # Enable on-screen keyboard
      "org/gnome/desktop/a11y/applications".screen-keyboard-enabled = true;
      "org/gnome/shell".enabled-extensions = (map (extension: extension.extensionUuid) home.packages);
      # Dash-to-Dock settings for a better touch screen experience
      "org/gnome/shell/extensions/dash-to-dock" = {
        background-opacity = 0.80000000000000004;
        custom-theme-shrink = true;
        dash-max-icon-size = 48;
        dock-fixed = true;
        dock-position = "LEFT";
        extend-height = true;
        height-fraction = 0.60999999999999999;
        hot-keys = false;
        preferred-monitor = -2;
        preferred-monitor-by-connector = "eDP-1";
        scroll-to-focused-application = true;
        show-apps-at-top = true;
        show-mounts = true;
        show-show-apps-button = true;
        show-trash = false;
      };
    };

    home.packages = with pkgs.gnomeExtensions; [
      dash-to-dock
    ];
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware.graphics = {
    extraPackages = with pkgs; [
      #amdvlk
      #rocmPackages.clr
      #rocmPackages.clr.icd
    ];
    extraPackages32 = with pkgs.driversi686Linux; [
      #amdvlk
    ];
  };


  ##########################################################
  # Boot
  ##########################################################
  boot = {
    initrd = {
      availableKernelModules = [ ];
      kernelModules = [ ];
      # Required for Plymouth (password prompt)
      systemd.enable = true;
    };

    kernelModules = [ ];
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
      grub = {
        enable = false;
        configurationLimit = 5;
        device = "nodev";
        #efiInstallAsRemovable = true;
        efiSupport = true;
        memtest86.enable = true;
        theme = pkgs.sleek-grub-theme.override { withStyle = "dark"; };
        useOSProber = true;
        #users.${vars.user}.hashedPasswordFile = "/etc/users/grub";
      };
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        # Console resolution
        consoleMode = "auto";
        editor = false;
        memtest86.enable = true;
      };
      timeout = 1;
    };

    supportedFilesystems = [ "btrfs" ];
  };


  ##########################################################
  # Network
  ##########################################################

}
