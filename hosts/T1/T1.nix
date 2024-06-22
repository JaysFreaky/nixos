{ config, host, inputs, lib, pkgs, vars, ... }:
let
  # Hyprland display scale
  scale = 1.25;
in {
  imports = lib.optional (builtins.pathExists ./swap.nix) ./swap.nix;

  ##########################################################
  # Custom Options
  ##########################################################
  # Desktop - gnome, hyprland
  gnome.enable = true;
  #hyprland.enable = true;

  # Hardware - audio (on by default), bluetooth, fp_reader
  bluetooth.enable = true;

  # Programs / Features - 1password, alacritty, flatpak, gaming, kitty, lact, syncthing
  # Whichever terminal is defined in flake.nix is auto-enabled
  "1password".enable = true;
  gaming.enable = true;
  lact.enable = true;
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
    # Hardware
      corectrl                # CPU/GPU control
      polychromatic           # Razer lighting GUI

    # Messaging
      discord                 # Discord

    # Monitoring
      amdgpu_top              # GPU stats
      nvtopPackages.amd       # GPU stats
      zenmonitor              # CPU stats

    # Multimedia
      mpv                     # Media player
      plex-media-player       # Plex player
      spotify                 # Music

    # Notes
      obsidian                # Markdown notes
    ];
  };

  programs = {
    # PWM fan control
    #coolercontrol.enable = true;

    gamescope.args = [
      "--adaptive-sync"
      #"--borderless"
      "--expose-wayland"
      "--filter fsr"
      "--fullscreen"
      "--framerate-limit 144"
      "--hdr-enabled"
      #"--mangoapp"  # Toggling doesn't work with this
      "--nested-height 1440"
      "--nested-refresh 144"
      "--nested-width 2560"
      #"--prefer-vk-device \"1002:73a5\""  # lspci -nn | grep -i vga
      "--rt"
    ];
  };

  services.openssh = {
    enable = lib.mkForce true;
    knownHosts."FW13".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAMoEb31xABf0fovDku5zBfBDI2sKCixc31wndQj5VhT jays@FW13";
  };


  ##########################################################
  # Home Manager Options
  ##########################################################
  home-manager.users.${vars.user} = {
    programs.mangohud.settings = {
      # lspci -D | grep -i vga
      pci_dev = "0:0a:00.0";
      fps_limit = 144;
      gpu_fan = true;
      gpu_voltage = true;
      table_columns = lib.mkForce 6;
    };

  /*wayland.windowManager.hyprland.settings = {
      # hyprctl monitors all
      # name,resolution@htz,position,scale
      monitor = [
        ",preferred,auto,auto"
        #"eDP-1,2560x1440@144,0x0,${toString scale}"
      ];
    }; */
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
    bluetooth.powerOnBoot = lib.mkForce true;

    # Control CPU / case fans
    fancontrol = let
      gpuFC = "pci0000:00/0000:00:03.1/0000:08:00.0/0000:09:00.0/0000:0a:00.0";
    in {
      enable = false;
      config = ''
        INTERVAL=10
        DEVPATH=hwmon2=devices/${gpuFC} hwmon3=devices/pci0000:00/0000:00:18.3 hwmon7=devices/platform/nct6775.656
        DEVNAME=hwmon2=amdgpu hwmon3=zenpower hwmon7=nct6798
        FCTEMPS=hwmon7/pwm1=hwmon2/temp1_input hwmon7/pwm2=hwmon3/temp2_input
        FCFANS=hwmon7/pwm1=hwmon7/fan1_input hwmon7/pwm2=hwmon7/fan2_input
        MINTEMP=hwmon7/pwm1=40 hwmon7/pwm2=40
        MAXTEMP=hwmon7/pwm1=80 hwmon7/pwm2=80
        # Always spin @ MINPWM until MINTEMP
        MINSTART=hwmon7/pwm1=0 hwmon7/pwm2=0
        MINSTOP=hwmon7/pwm1=64 hwmon7/pwm2=64
        # Fans @ 25% until 40 degress
        MINPWM=hwmon7/pwm1=64 hwmon7/pwm2=64
        # Fans ramp to set max @ 80 degrees - Case: 55% / CPU: 85%
        MAXPWM=hwmon7/pwm1=140 hwmon7/pwm2=217
      '';
    };

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        amdvlk
        libvdpau-va-gl
        rocmPackages.clr
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
      theme = "rog_2";
      themePackages = [
        # Overriding installs the one theme instead of all 80, reducing the required size
        # Theme previews: https://github.com/adi1090x/plymouth-themes
        (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "rog_2" ]; })
      ];
    };

    # Zenpower uses same PCI device as k10temp, so disabling k10temp
    blacklistedKernelModules = [ "k10temp" ];
    kernelModules = [
      "zenpower"
    ];
    extraModulePackages = with config.boot.kernelPackages; [
      zenpower
    ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "amd_pstate=active"
      #"quiet"
      #"splash"
    ];
    supportedFilesystems = [ "btrfs" ];

    initrd = {
      availableKernelModules = [ ];
      kernelModules = [
        "nfs"
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
