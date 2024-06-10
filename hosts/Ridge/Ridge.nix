{ config, host, lib, pkgs, vars, ... }:
let
  # Hyprland display scale
  #scale = 1.25;

  # GPU temp monitoring via fancontrol
  gpuFC = "pci0000:00/0000:00:03.1/0000:08:00.0/0000:09:00.0/0000:0a:00.0";

  # GPU Undervolting
  gpuUV = pkgs.writeShellScriptBin "gpu_uv.sh" ''
    #!/usr/bin/env bash

    # Find persistant device: readlink -f /sys/class/drm/card#/device
    GPU=/sys/devices/pci0000\:00/0000\:00\:03.1/0000\:08\:00.0/0000\:09\:00.0/0000\:0a\:00.0

    # GPU min clock - default min is 500
    echo "Setting GPU min clock"
    echo s 1 2100 | tee "$GPU"/pp_od_clk_voltage
    # GPU max clock - default max is 2664
    echo "Setting GPU max clock"
    echo s 2 2200 | tee "$GPU"/pp_od_clk_voltage
    # Voltage offset - default mV is 1200
    echo "Setting voltage offset"
    echo vo -150 | tee "$GPU"/pp_od_clk_voltage
    # VRAM max clock - default max is 1124 - not adjusting
    #echo "Setting VRAM clock"
    #echo m 1 1124 | tee "$GPU"/pp_od_clk_voltage
    # Apply values
    echo "Applying undervolt settings"
    echo c | tee "$GPU"/pp_od_clk_voltage

    # Power usage limit - default wattage is 284 (first 3 numbers are watts)
    echo "Setting power usage limit"
    echo 284000000 | tee "$GPU"/hwmon/hwmon2/power1_cap

    # Performance level: auto, low, high, manual
    echo "Setting performance level"
    echo manual | tee "$GPU"/power_dpm_force_performance_level
    # Power level mode: cat pp_power_profile_mode
    echo "Setting power level mode to 3D Fullscreen"
    echo 1 | tee "$GPU"/pp_power_profile_mode
    # GPU power states: cat pp_dpm_sclk
    echo "Enabling all GPU power states"
    echo 2 | tee "$GPU"/pp_dpm_sclk
    # VRAM power states: cat pp_dpm_mclk
    echo "Enabling all VRAM power states"
    echo 3 | tee "$GPU"/pp_dpm_mclk
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
    # Lact config not needed if undervolt service works
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
  };

  jovian.steam = {
    # Steam Deck UI
    enable = false;
    # Start in Steam UI
    autoStart = true;
    # Switch to desktop - Use 'gamescope-wayland' for no desktop
    desktopSession = "gnome";
    user = "${vars.user}";
  };

  programs = {
    # PWM fan control - not needed if fancontrol works
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
      #"--prefer-vk-device \"1002:73a5\""
      "--rt"
    ];
  };

/*services = {
    displayManager.autoLogin = {
      enable = lib.mkForce true;
      user = "${vars.user}";
    };

    # Disable GDM with jovian.steam.autoStart enabled
    xserver.displayManager.gdm.enable = lib.mkForce false;
  }; */


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
    fancontrol = {
      #enable = true;
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

    opengl = {
      enable = true;
      # DRI are Mesa drivers
      driSupport = true;
      driSupport32Bit = true;
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

  # Restart GPU undervolt service upon resume
  powerManagement.resumeCommands = ''
    systemctl restart gpu_uv.service
  '';

  services.hardware.openrgb.enable = true;

  # Create a service to auto undervolt GPU
  systemd.services.gpu_uv = {
    after = [ "multi-user.target" "rc-local.service" "systemd-user-sessions.service" ];
    description = "Set AMDGPU Undervolt";
    wantedBy = [ "multi-user.target" ];
    wants = [ "modprobe@amdgpu.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      ExecStart = ''${gpuUV}/bin/gpu_uv.sh'';
      ExecReload = ''${gpuUV}/bin/gpu_uv.sh'';
    };
  };


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
      # Undervolt GPU - https://wiki.archlinux.org/title/AMDGPU#Boot_parameter
      "amdgpu.ppfeaturemask=0xffffffff"
      #"quiet"
      #"splash"
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
