{
  config,
  lib,
  pkgs,
  #cfgHosts,
  cfgOpts,
  myUser,
  ...
}: let
  protonMB = pkgs.protonmail-bridge-gui;  # pkgs or stable
in {
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
    desktops = {
      hyprland.enable = false;
      kde = {
        enable = true;
        gpuWidget = "gpu/gpu0/temperature";
      };
    };

    hardware = {
      bluetooth.enable = false;
      nvidia.enable = true;
    };

    # "1password", flatpak, gaming, kitty, openrgb, plex, spicetify, syncthing, vm, wezterm, yubikey
    "1password".enable = true;
    gaming.enable = true;
    plex.enable = true;
    spicetify.enable = true;
    syncthing.enable = true;
    vm.enable = true;
    yubikey.enable = true;
  };


  ##########################################################
  # System Packages / Variables
  ##########################################################
  environment = {
    systemPackages = [
      protonMB                # GUI bridge for Thunderbird
    ] ++ builtins.attrValues {
      inherit (pkgs)
      # Communication
        discord                 # Discord
        signal-desktop          # Signal
        thunderbird-latest      # Email client

      # Hardware
        polychromatic           # Razer lighting GUI

      # Misc
        calibre                 # Book organization

      # Multimedia
        #mpv                    # Media player
        picard                  # Music tagger
        pocket-casts            # Podcast player
        tauon                   # Music player
        tidal-dl                # Tidal downloader
        tidal-hifi              # Tidal client

      # Networking

      # Productivity
        libreoffice-qt6-fresh   # Office suite
        obsidian                # Markdown notes
      ;
    };
    # Set Firefox to use GPU for video codecs
    variables.MOZ_DRM_DEVICE = "/dev/dri/by-path/pci-0000:01:00.0-render";
  };

  programs = {
    adb.enable = true;  # Android flashing
    coolercontrol.enable = lib.mkIf (!config.hardware.fancontrol.enable) true;

    gamescope = {
      args = [
        "--prefer-vk-device \"10de:2684\""  # lspci -nn | grep -i vga
        "--hdr-enabled"
      ];
      env = {
        DXVK_HDR = "1";
        # Not sure if required w/ pkgs.gamescope-wsi
        ENABLE_GAMESCOPE_WSI = "1";
      };
    };
  };

  services = {
    fwupd.enable = true;
    scx = {
      enable = true;
      scheduler = "scx_rusty"; # or "scx_lavd"
    };
  };

  system.stateVersion = "24.11";
  users.users.${myUser}.extraGroups = [ "fancontrol" ];


  ##########################################################
  # Home Manager
  ##########################################################
  home-manager.users.${myUser} = {
    home.stateVersion = "24.11";

    # lspci -D | grep -i vga
    programs.mangohud.settings = {
      gpu_voltage = true;
      gpu_fan = true;
      pci_dev = "0:01:00.0";
      table_columns = lib.mkForce 6;
    };

    wayland.windowManager.hyprland.settings = lib.mkIf (cfgOpts.desktops.hyprland.enable) {
      # 'hyprctl monitors all' - "name, widthxheight@rate, position, scale"
      #monitor = lib.mkForce [ "eDP-1, ${builtins.toString cfgHosts.width}x${builtins.toString cfgHosts.height}@${builtins.toString cfgHosts.refresh}, 0x0, ${builtins.toString cfgHosts.scale}" ];
    };

    xdg.configFile."autostart/ProtonMailBridge.desktop".text = (lib.strings.replaceStrings
      [ "Exec=protonmail-bridge-gui" ]
      [ "Exec=${lib.getExe protonMB} --no-window" ]
      (lib.strings.fileContents "${protonMB}/share/applications/proton-bridge-gui.desktop")
    );
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
    fancontrol = {
      enable = true;
      config = let
      # Hardware
        cpuMon = "hwmon1";
        cpuName = "k10temp";
        cpuPath = "devices/pci0000:00/0000:00:18.3";
        fanMon = "hwmon3";
        fanName = "nct6686";
        fanPath = "devices/platform/nct6687.2592";
      # Fan speeds -- value = percent * 2.55
        caseMin = "100"; # 40%
        caseMax = "102"; # 40%
        cpuMin = "64"; # 25%
        cpuMax = "217"; # 85%
      in ''
        INTERVAL=10
        DEVPATH=${cpuMon}=${cpuPath} ${fanMon}=${fanPath}
        DEVNAME=${cpuMon}=${cpuName} ${fanMon}=${fanName}
        FCTEMPS=${fanMon}/pwm1=${cpuMon}/temp1_input ${fanMon}/pwm2=${cpuMon}/temp1_input
        FCFANS=${fanMon}/pwm1=${fanMon}/fan1_input ${fanMon}/pwm2=${fanMon}/fan2_input
        MINTEMP=${fanMon}/pwm1=40 ${fanMon}/pwm2=40
        MAXTEMP=${fanMon}/pwm1=80 ${fanMon}/pwm2=80
        MINSTART=${fanMon}/pwm1=30 ${fanMon}/pwm2=30
        MINSTOP=${fanMon}/pwm1=${cpuMin} ${fanMon}/pwm2=${caseMin}
        # Fans @ 25%/40% until 40 degress
        MINPWM=${fanMon}/pwm1=${cpuMin} ${fanMon}/pwm2=${caseMin}
        # CPU fan ramps to 85% @ 80 degrees
        MAXPWM=${fanMon}/pwm1=${cpuMax} ${fanMon}/pwm2=${caseMax}
      '';
    };

    nvidia.prime = {
      amdgpuBusId = "PCI:13:0:0";
      nvidiaBusId = "PCI:1:0:0";
      #sync.enable = true;
    };

    openrazer = {
      enable = true;
      users = [ myUser ];
    };
  };


  ##########################################################
  # Boot
  ##########################################################
  boot = {
    initrd.systemd.enable = true;

    blacklistedKernelModules = [ "amdgpu" ]; # Disable iGPU
    extraModulePackages = [ config.boot.kernelPackages.nct6687d ];
    kernelModules = [
      "nct6687"
      "nfs"
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
      timeout = 2;
    };

    plymouth = {
      enable = true;
      theme = "loader"; # Previews: https://github.com/adi1090x/plymouth-themes
      # Overriding installs a single theme instead of all 80, reducing the required size
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
