{ host, lib, pkgs, vars, ... }: {
  imports = lib.optional (builtins.pathExists ./swap.nix) ./swap.nix;

  ##########################################################
  # Custom Options
  ##########################################################
  # Desktop - gnome, hyprland
  gnome.enable = true;

  # Hardware - audio (on by default), bluetooth, fp_reader
  #bluetooth.enable = true;

  # Programs / Features - alacritty, flatpak, gaming, kitty, syncthing
  # Whichever terminal is defined in flake.nix is auto-enabled
  #gaming.enable = true;

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
    ];
  };

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

  # Disable GDM with jovian.steam.autoStart enabled
  services.xserver.displayManager.gdm.enable = lib.mkForce false;


  ##########################################################
  # Home Manager Options
  ##########################################################
  home-manager.users.${vars.user} = { config, lib, ... }: {
    dconf.settings = {
      # Enable on-screen keyboard
      "org/gnome/desktop/a11y/applications" = {
        screen-keyboard-enabled = true;
      };
      # Dash-to-Dock settings for a better touch screen experience
      "org/gnome/shell/extensions/dash-to-dock" = lib.mkForce {
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
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        #amdvlk
        #rocmPackages.clr.icd
      ];
      extraPackages32 = with pkgs.driversi686Linux; [
        #amdvlk
      ];
    };
  };


  ##########################################################
  # Boot / Encryption
  ##########################################################
  boot = {
    kernelModules = [ ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "quiet" "splash" ];
    supportedFilesystems = [ "btrfs" ];

    initrd = {
      availableKernelModules = [ ];
      kernelModules = [ ];
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
        theme = pkgs.sleek-grub-theme.override { withStyle = "dark"; };
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
