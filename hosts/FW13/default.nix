{
  config,
  lib,
  myUser,
  #nixPath,
  pkgs,
  #stable,
  ...
}: let
  # Patch kernel to log usbpd instead of warn
  fw-usbpd-charger = pkgs.callPackage ./usbpd { kernel = config.boot.kernelPackages.kernel; };

  protonMB = pkgs.protonmail-bridge-gui;  # pkgs or stable

  # Whether or not to enable the fingerprint reader
  useFP = true;
in {
  imports = [
    ./filesystems.nix
    ./hardware-configuration.nix
  ];

  ##########################################################
  # Custom Options
  ##########################################################
  myHosts = {
    width = 2256;
    height = 1504;
    refresh = 60;
    scale = 1.5;
  };

  myOptions = {
    desktops = {
      cosmic.enable = false;
      gnome.enable = true;
    };

    hardware = {
      amdgpu.enable = true;
      bluetooth.enable = true;
    };

    # "1password", alacritty, flatpak, gaming, kitty, plex, spicetify, stylix, syncthing, wezterm
    "1password".enable = true;
    gaming.enable = true;
    plex.enable = true;
    spicetify.enable = true;
    stylix = {
      enable = true;
      wallpaper = {
        #dark = "${nixPath}/assets/wallpapers/FW13/dark.png";
        #light = "${nixPath}/assets/wallpapers/FW13/light.png";
      };
    };
    syncthing.enable = true;
    #wezterm.enable = true;
  };


  ##########################################################
  # System Packages / Variables
  ##########################################################
  environment = {
    systemPackages = with pkgs; let
      s2idle = import ./s2idle.nix { inherit pkgs; };
    in [
    # Communication
      discord                 # Discord
      protonMB                # GUI bridge for Thunderbird
      thunderbird-latest      # Email client

    # Framework Hardware
      framework-tool          # Swiss army knife for FWs
      iio-sensor-proxy        # Ambient light sensor | 'monitor-sensor'
      s2idle                  # Environment for suspend testing | 's2idle ./amd_s2idle.py'
      sbctl                   # Secure boot key manager

    # Monitoring
      powertop                # Power stats
      zenmonitor              # CPU stats

    # Multimedia
      #mpv                    # Media player
      #smplayer               # MPV frontend

    # Networking
      brave                   # Alt browser
      protonvpn-gui           # VPN client

    # Productivity
      libreoffice-fresh       # Office suite
      obsidian                # Markdown notes
    ];
    # Set Firefox to use GPU for video codecs
    variables.MOZ_DRM_DEVICE = "/dev/dri/by-path/pci-0000:c1:00.0-render";
  };

  programs = {
    adb.enable = true;  # Android flashing
    gamescope.args = [ "--prefer-vk-device \"1002:15bf\"" ];  # lspci -nn | grep -i vga
  };

  system.stateVersion = "24.11";


  ##########################################################
  # Home Manager
  ##########################################################
  home-manager.users.${myUser} = { config, ... }: let
    ee-pkg = config.services.easyeffects.package;
    eePreset = config.services.easyeffects.preset;
  in {
    #imports = [ ./fetch-logo.nix ];

    dconf.settings = {
      "org/gnome/settings-daemon/plugins/power".ambient-enabled = false;  # Auto screen brightness
      "org/gnome/shell".enabled-extensions = [ "Battery-Health-Charging@maniacx.github.com" ];
      "org/gnome/shell/extensions/Battery-Health-Charging" = let
        bal = 85;
        ful = 90;
      in {
        amend-power-indicator = true;
        bal-end-threshold = bal;
        charging-mode = "ful";
        current-bal-end-threshold = bal;
        current-ful-end-threshold = ful;
        ful-end-threshold = ful;
        indicator-position = 4;
        show-system-indicator = false;
      };
      "org/gnome/shell/extensions/power-profile-switcher" = {
        # performance, balanced, power-saver
        ac = "performance";
        bat = "power-saver";
      };
    };

    home.packages = with pkgs.gnomeExtensions; [ battery-health-charging ];
    home.stateVersion = "24.11";

    # lspci -D | grep -i vga
    programs.mangohud.settings.pci_dev = "0:c1:00.0";

    # https://github.com/FrameworkComputer/linux-docs/tree/main/easy-effects
    services.easyeffects = {
      enable = true;
      preset = "fw13-easy-effects";
    };

    # Workaround for easyeeffects preset not auto loading
      # https://github.com/nix-community/home-manager/issues/5185
    systemd.user.services.easyeffects.Service.ExecStartPost = [ "${lib.getExe ee-pkg} --load-preset ${eePreset}" ];

    xdg.configFile = {
      "autostart/ProtonMailBridge.desktop".text = lib.strings.concatLines [
        (lib.strings.replaceStrings
          [ "Exec=protonmail-bridge-gui" ]
          [ "Exec=${lib.getExe protonMB} --no-window" ]
          (lib.strings.fileContents "${protonMB}/share/applications/proton-bridge-gui.desktop")
        )
        "X-GNOME-Autostart-enabled=true"
      ];

      "autostart/ProtonVPN.desktop".text = lib.strings.concatLines [
        (lib.strings.replaceStrings
          [ "Exec=protonvpn-app" ]
          [ "Exec=${lib.getExe pkgs.protonvpn-gui} --start-minimized" ]
          (lib.strings.fileContents "${pkgs.protonvpn-gui}/share/applications/protonvpn-app.desktop")
        )
        "X-GNOME-Autostart-enabled=true"
      ];

      "easyeffects/output/${eePreset}.json".source = pkgs.fetchFromGitHub {
        owner = "FrameworkComputer";
        repo = "linux-docs";
        rev = "e70bfc83dbdcbcd2cd47259a823a17d5ccce14c2";
        sha256 = "sha256-o4unZQBGD6nejo1KeZ9x6zGOYOHbSq7WtarGOdiu5EM=";
      } + "/easy-effects/${eePreset}.json";
    };
  };


  ##########################################################
  # Hardware
  ##########################################################
  hardware = {
    bluetooth.powerOnBoot = lib.mkForce false;
    enableAllFirmware = true;
    firmware = [ pkgs.linux-firmware ];
    #framework.laptop13.audioEnhancement.enable = true;

    # Allow 5GHz wifi
    wirelessRegulatoryDatabase = true;
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
    # Auto-tuning - to use powertop bin, pkg must be declared in systemPackages
    powertop.enable = true;
  };

  services = {
    # 'sudo fprintd-enroll'
    fprintd.enable = (
      if (useFP)
        then lib.mkForce true
      else lib.mkForce false
    );

    fwupd = {
      enable = true;
      #extraRemotes = ["lvfs-testing"];
    };

    logind = {
      lidSwitch = "suspend";
      powerKey = "suspend-then-hibernate";
      extraConfig = ''
        IdleAction=suspend
        IdleActionSec=10m
      '';
    };

    udev.extraRules = let
      # GPU performance adjusts based upon power input
      gpuPowerMode = pkgs.writeShellScriptBin "gpu-power" ''
        # Find persistant GPU path: readlink -f /sys/class/drm/card1/device
        GPU='/sys/devices/pci0000:00/0000:00:08.1/0000:c1:00.0'
        echo "$1" > "$GPU"/power_dpm_force_performance_level
      '';
    in ''
      ACTION=="add", SUBSYSTEM=="acpi", DRIVERS=="button", ATTRS{hid}=="PNP0C0D", ATTR{power/wakeup}="disabled"
      ACTION=="change", SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${lib.getExe gpuPowerMode} low"
      ACTION=="change", SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${lib.getExe gpuPowerMode} high"
    '';

    upower = {
      enable = true;
      percentageLow = 15;
      percentageCritical = 10;
      percentageAction = 5;
      criticalPowerAction = "Hibernate";
    };
  };

  # Sleep for 30m then hibernate
  systemd.sleep.extraConfig = ''
    AllowHibernation=yes
    HibernateDelaySec=30m
    HibernateMode=shutdown
    SuspendState=mem
  '';


  ##########################################################
  # Boot
  ##########################################################
  boot = {
    initrd = {
      availableKernelModules = [ "cryptd" ];
      systemd.enable = true;
    };

    blacklistedKernelModules = [
      #"framework_laptop" # Taints kernel when debugging w/ amd_s2idle
    ];
    # Allow 5GHz wifi
    extraModprobeConfig = "options cfg80211 ieee80211_regdom=\"US\"";
    extraModulePackages = [
      fw-usbpd-charger  # Taints kernel when debugging w/ amd_s2idle
    ];
    kernelModules = [ "nfs" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "amd_iommu=off" # Fixes VP9/VAAPI video glitches
      #"ipv6.disable=1" # Currently breaks wireguard in protonvpn-gui
      "quiet"
    ];

    # https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      systemd-boot = {
        enable = (
          if (config.boot.lanzaboote.enable)
            then lib.mkForce false
          else true
        );
        configurationLimit = 5;
        consoleMode = "auto";
        editor = false;
        memtest86.enable = config.boot.loader.systemd-boot.enable;
      };
      timeout = 2;
    };

    plymouth = {
      enable = true;
      theme = "framework";
      themePackages = [ pkgs.framework-plymouth ];
    };

    supportedFilesystems = [
      "btrfs"
      "nfs"
    ];
  };


  ##########################################################
  # Network
  ##########################################################
  networking = {
    enableIPv6 = false;
    firewall.checkReversePath = "loose";
    networkmanager.wifi = {
      backend = "iwd";  # iwd performs better on AMD FW models
      macAddress = "stable-ssid";
      powersave = false;
    };
  };
}
