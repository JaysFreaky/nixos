{ config, host, lib, pkgs, vars, ... }:
let
  # Hyprland display scale
  #scale = 1.25;

  # Generate GPU path for Firefox environment variable
  gpuCard = "$(stat /dev/dri/* | grep card | cut -d':' -f 2 | tr -d ' ')";

  # AMDGPU Undervolting
  gpuUV = pkgs.writeShellScriptBin "gpu_uv.sh" ''
    #!/usr/bin/env bash

    # Find persistant device: readlink -f /sys/class/drm/card#/device
    gpuDevice=/sys/devices/pci0000:00/0000:00:03.1/0000:08:00.0/0000:09:00.0/0000:0a:00.0

    # Set maximum MHz
    echo s 1 2250 | sudo tee "$gpuDevice"/pp_od_clk_voltage
    # Set voltage offset
    echo vo -30 | sudo tee "$gpuDevice"/pp_od_clk_voltage
    # Apply UV values
    echo c | sudo tee "$gpuDevice"/pp_od_clk_voltage

    # Set max wattage (first 3 numbers are wattage - 284 default)
    echo 255000000 > "$gpuDevice"/hwmon/hwmon2/power1_cap

    # Set fan mode: 0=off, 1=manual, 2=auto
    #echo 2 > "$gpuDevice"/hwmon/hwmon2/pwm1_enable
    # Set fan pwm max % (mode must be manual) - 128=50%; 255=100%
    #echo 128 > "$gpuDevice"/hwmon/hwmon2/pwm1_max

    # Set power profile level: auto, low, high, manual
    echo manual > "$gpuDevice"/power_dpm_force_performance_level
    # Set power profile mode: cat "$gpuDevice"/pp_power_profile_mode
    echo 1 > "$gpuDevice"/pp_power_profile_mode
    # Set highest VRAM power state: cat "$gpuDevice"/pp_dpm_mclk
    echo 3 > "$gpuDevice"/pp_dpm_mclk
  '';
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
    #etc."lact/config.yaml".text = ''
    #'';

    systemPackages = with pkgs; [
    # Hardware
      corectrl                # CPU/GPU control

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

    variables = {
      # Set Firefox to use GPU for video codecs
      MOZ_DRM_DEVICE = gpuCard;
    };
  };

  programs = {
    # PWM fan control
    coolercontrol.enable = true;

    gamescope.args = [
      "--adaptive-sync"
      #"--borderless"
      #"--expose-wayland"
      "--filter fsr"
      "--fullscreen"
      "--framerate-limit 144"
      "--hdr-enabled"
      # Toggling doesn't work using --mangoapp
      #"--mangoapp"
      "--nested-height 1440"
      "--nested-refresh 144"
      "--nested-width 2560"
      #"--prefer-vk-device \"1002:73a5\""
      "--rt"
    ];
  };

  # Create a service to auto-undervolt
  systemd.services.gpu_uv = {
    after = [ "multi-user.target" ];
    description = "Set AMDGPU Undervolt";
    wantedBy = [ "multi-user.target" ];
    wants = [ "modprobe@amdgpu.service" ];
    serviceConfig = {
      ExecStart = ''${gpuUV}/bin/gpu_uv.sh'';
      Type = "oneshot";
    };
  };


  ##########################################################
  # Home Manager Options
  ##########################################################
  /*
  home-manager.users.${vars.user} = {
    wayland.windowManager.hyprland.settings = {
      # hyprctl monitors all
      # name,resolution@htz,position,scale
      monitor = [
        #",preferred,auto,auto"
        #"eDP-1,2560x1440@144,0x0,${toString scale}"
      ];
    };
  }; */


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
        amdvlk
        libvdpau-va-gl
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
      "openrazer"
      "zenpower"
    ];
    extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "amd_pstate=active"
      # Adjust GPU clocks/voltages - https://wiki.archlinux.org/title/AMDGPU#Boot_parameter
      "amdgpu.ppfeaturemask=0xffffffff"
      #"quiet"
    ];
    supportedFilesystems = [ "btrfs" ];

    initrd = {
      availableKernelModules = [ ];
      kernelModules = [
        "amdgpu"
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
        theme = "pkgs.sleek-grub-theme.override { withStyle = "dark"; }";
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
