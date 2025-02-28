{
  config,
  inputs,
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
  myHosts = {
    width = 2560;
    height = 1440;
    refresh = 144;
    scale = 1.25;
  };

  myOptions = {
    hardware = {
      amdgpu = {
        enable = true;
        undervolt = {
          enable = true;
          gpu = "/sys/devices/pci0000:00/0000:00:03.1/0000:08:00.0/0000:09:00.0/0000:0a:00.0"; # RX 6950 XT
          clockMin = 2100; # Default: 500
          clockMax = 2200; # Default: 2664
          powerLimit = 300000000; # Default: 284W
          voltOffset = -150; # Default: 1200mV; drops to 1050
          vramClock = 1124; # Default: 1124
        };
      };
      bluetooth.enable = true;
    };

    #"1password".enable = true;
    openrgb.enable = true;
    #syncthing.enable = true;
  };


  ##########################################################
  # System Packages / Variables
  ##########################################################
  environment = {
    systemPackages = [ ];
    # Set Firefox to use GPU for video codecs
    variables.MOZ_DRM_DEVICE = "/dev/dri/by-path/pci-0000:0a:00.0-render";
  };

  jovian = {
    decky-loader = {
      enable = true;
      user = myUser;
    };

    hardware = {
      amd.gpu.enableBacklightControl = false;
      has.amd.gpu = true;
    };

    steam = {
      # Enable SteamOS UI
      enable = true;
      # Boot into SteamOS UI
      autoStart = true;
      # Switch to desktop - Use 'gamescope-wayland' for no desktop
      desktopSession = "plasma";
      user = myUser;
    };
  };

  # lspci -nn | grep -i vga
  #programs.gamescope.args = [ "--prefer-vk-device \"1002:73a5\"" ];

  services = {
    desktopManager.plasma6.enable = true;
    scx = {
      enable = true;
      scheduler = "scx_rusty"; # or "scx_lavd"
    };
  };

  system.autoUpgrade = {
    enable = false;
    allowReboot = true;
    dates = "weekly";
    flags = [ "--commit-lock-file" ];
    flake = inputs.self.outPath;
    randomizedDelaySec = "45min";
    rebootWindow = {
      lower = "02:00";
      upper = "06:00";
    };
  };

  system.stateVersion = "24.11";


  ##########################################################
  # Home Manager
  ##########################################################
  home-manager.users.${myUser} = {
    home.stateVersion = "24.11";

    /*
    # lspci -D | grep -i vga
    programs.mangohud.settings = {
      gpu_voltage = true;
      gpu_fan = true;
      pci_dev = "0:0a:00.0";
      table_columns = lib.mkForce 6;
    };
    */
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
    fancontrol = {
      enable = true;
      config = let 
      # Hardware
        cpuMon = "hwmon3";
        cpuName = "zenpower";
        cpuPath = "devices/pci0000:00/0000:00:18.3";
        fanMon = "hwmon2";
        fanName = "nct6798";
        fanPath = "devices/platform/nct6775.656";
        gpuMon = "hwmon1";
        gpuName = "amdgpu";
        gpuPath = "devices/pci0000:00/0000:00:03.1/0000:08:00.0/0000:09:00.0/0000:0a:00.0";
      # Fan speeds -- value = percent * 2.55
        caseMin = "66"; # 25%
        caseMax = "140"; # 55%
        cpuMin = "64"; # 25%
        cpuMax = "217"; # 85%
      in ''
        INTERVAL=10
        DEVPATH=${gpuMon}=${gpuPath} ${fanMon}=${fanPath} ${cpuMon}=${cpuPath}
        DEVNAME=${gpuMon}=${gpuName} ${fanMon}=${fanName} ${cpuMon}=${cpuName}
        FCTEMPS=${fanMon}/pwm1=${gpuMon}/temp1_input ${fanMon}/pwm2=${cpuMon}/temp2_input
        FCFANS=${fanMon}/pwm1=${fanMon}/fan1_input ${fanMon}/pwm2=${fanMon}/fan2_input
        MINTEMP=${fanMon}/pwm1=40 ${fanMon}/pwm2=40
        MAXTEMP=${fanMon}/pwm1=80 ${fanMon}/pwm2=80
        MINSTART=${fanMon}/pwm1=30 ${fanMon}/pwm2=30
        MINSTOP=${fanMon}/pwm1=${caseMin} ${fanMon}/pwm2=${cpuMin}
        # Fans @ 25% until 40 degress
        MINPWM=${fanMon}/pwm1=${caseMin} ${fanMon}/pwm2=${cpuMin}
        # Fans ramp to set max @ 80 degrees - Case: 55% / CPU: 85%
        MAXPWM=${fanMon}/pwm1=${caseMax} ${fanMon}/pwm2=${cpuMax}
      '';
    };

    xone.enable = true;
  };


  ##########################################################
  # Boot
  ##########################################################
  boot = {
    initrd.systemd.enable = true;

    # Zenpower uses same PCI device as k10temp
    blacklistedKernelModules = [ "k10temp" ];
    extraModulePackages = [ config.boot.kernelPackages.zenpower ];
    kernelModules = [
      "nct6775"
      "nfs"
      "zenpower"
    ];
    kernelPackages = (
      if (config.services.scx.enable)
        then pkgs.linuxPackages_cachyos
      else pkgs.linuxPackages_latest
    );
    kernelParams = [
      "amd_pstate=active"
      "quiet"
    ];

    loader = {
      efi = {
        #canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub = {
        enable = true;
        configurationLimit = 5;
        device = "nodev";
        efiInstallAsRemovable = true;
        efiSupport = true;
        memtest86.enable = true;
        theme = pkgs.sleek-grub-theme.override { withStyle = "dark"; };
        useOSProber = true;
        #users.${myUser}.hashedPasswordFile = "/etc/users/grub";
      };
      timeout = 1;
    };

    plymouth = {
      enable = true;
      theme = "rog_2"; # Previews: https://github.com/adi1090x/plymouth-themes
      # Overriding installs the one theme instead of all 80, reducing the required size
      themePackages = [ (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "${config.boot.plymouth.theme}" ]; }) ];
    };

    supportedFilesystems = [
      "btrfs"
      "nfs"
    ];
  };


  ##########################################################
  # Network
  ##########################################################
}
