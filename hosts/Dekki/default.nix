{
  config,
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
    hardware = {
      #amdgpu.enable = true;
      bluetooth.enable = true;
    };

    "1password".enable = true;
    plex.enable = true;
    syncthing.enable = true;
  };


  ##########################################################
  # System Packages / Variables
  ##########################################################
  environment = {
    systemPackages = [
    # Monitoring
      pkgs.amdgpu_top              # GPU stats
      pkgs.nvtopPackages.amd       # GPU stats
    ];
    # Set Firefox to use GPU for video codecs
    variables.MOZ_DRM_DEVICE = "/dev/dri/by-path/pci-0000:04:00.0-render";
  };

  jovian = {
    decky-loader = {
      enable = true;
      user = myUser;
    };

    devices.steamdeck = {
      enable = true;
      autoUpdate = true;
      #enableGyroDsuService = true;
    };

    hardware.has.amd.gpu = true;

    steam = {
      # Enable SteamOS UI
      enable = true;
      # Boot into SteamOS UI
      autoStart = true;
      # Switch to desktop - Use 'gamescope-wayland' for no desktop
      desktopSession = "gnome";
      user = myUser;
    };
  };

  services.xserver.desktopManager.gnome.enable = true;
  system.stateVersion = "24.11";


  ##########################################################
  # Home Manager
  ##########################################################
  home-manager.users.${myUser} = let
    gnomeExts = [
      pkgs.gnomeExtensions.dash-to-dock
    ];
  in {
    dconf.settings = {
      # Enable on-screen keyboard
      "org/gnome/desktop/a11y/applications".screen-keyboard-enabled = true;
      "org/gnome/shell".enabled-extensions = (map (extension: extension.extensionUuid) gnomeExts);
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

    home.packages = gnomeExts;
    home.stateVersion = "24.11";
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware.graphics = {
    extraPackages = [
      pkgs.jovian-chaotic.mesa-radeonsi-jupiter
      pkgs.jovian-chaotic.mesa-radv-jupiter
    ];
    extraPackages32 = [ ];
  };


  ##########################################################
  # Boot
  ##########################################################
  boot = {
    initrd.systemd.enable = true;

    kernelPackages = (
      if (config.jovian.devices.steamdeck.enable)
        then pkgs.linuxPackages_jovian
      else pkgs.linuxPackages_latest
    );
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
        #users.${myUser}.hashedPasswordFile = "/etc/users/grub";
      };
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        consoleMode = "5";
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
