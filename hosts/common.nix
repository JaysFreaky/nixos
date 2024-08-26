{ config, inputs, lib, pkgs, stable, vars, ... }: let
  # Generate GPU path for Firefox environment variable
  gpuCard = "$(stat /dev/dri/* | grep card | cut -d':' -f 2 | tr -d ' ')";
  spf-flake = inputs.superfile.packages.${pkgs.system};
in {
  imports = (
    import ../modules/desktops ++
    import ../modules/hardware ++
    import ../modules/programs
  );

  ${vars.terminal}.enable = true;

  boot = {
    # Prioritize swap for hibernation only
    kernel.sysctl."vm.swappiness" = lib.mkDefault 0;
    # Clear /tmp on every boot
    tmp.cleanOnBoot = true;
  };

  console = {
    #font = "Lat2-Terminus16";
    keyMap = "us";
  };

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Chicago";

  environment = {
    # List packages installed in system profile. To search, run:
    # $ nix search wget
    # To use a stable version, add 'stable.' to the beginning of the package:
    # stable.wget
    systemPackages = with pkgs; [
    # ASCII Art
      asciiquarium                # Fishies swimming
      cbonsai                     # Bonsai growing

    # File Support
      #cifs-utils                 # SMB support
      exiftool                    # File metadata
      imagemagick                 # Image tools
      nfs-utils                   # NFS support
      p7zip                       # Zip encryption
      qview                       # Image viewer
      unzip                       # Zip files
      unrar                       # Rar files
      zip                         # Zip files

    # Notifications
      libnotify                   # Notification engine

    # Terminal
      bat                         # cat with syntax highlighting
      btop                        # Resource manager
      clinfo                      # OpenCL info | 'clinfo -l' or -a
      coreutils                   # GNU utilities
      dig                         # DNS tools
      fastfetch                   # Faster system info
      file                        # File information
      killall                     # Process killer
      libarchive                  # ISO extraction | 'bsdtar -xf IsoFile.iso OutputFile'
      lm_sensors                  # Hardware sensors | 'sensors-detect'
      lshw                        # Hardware config
      nix-tree                    # Browse nix store
      nvme-cli                    # Manage NVMe
      pciutils                    # Manage PCI | 'lspci'
      shellcheck                  # Script formating checker
      sops                        # Secret management
      spf-flake.superfile         # CLI file manager
      ssh-to-age                  # Convert SSH keys to Age
      #vars.terminal              # Terminal installed via variable
      tldr                        # Helper
      tmux                        # Multiplexor
      tree                        # Directory layout
      usbutils                    # Manage USB | 'lsusb'
      vim                         # Editor
      wget                        # Retriever
      wl-clipboard                # Enable wl-copy/wl-paste / used in Neovim
      xdg-utils                   # Environment integration
      xdragon                     # Terminal drag'n'drop
      zellij                      # Tmux alternative

    # Theming
      base16-schemes              # Presets
      variety                     # Wallpapers
    ];
    variables = {
      EDITOR = "nvim";
      TERMINAL = "${vars.terminal}";
      # Set Firefox to use GPU for video codecs
      MOZ_DRM_DEVICE = gpuCard;
    };
  };

  fonts.packages = with pkgs; [
    cantarell-fonts               # GNOME
    font-awesome                  # Icons
    inter                         # Waybar
    (nerdfonts.override {
      fonts = [
        "FiraCode"
        "JetBrainsMono"
        "NerdFontsSymbolsOnly"
        "Noto"
      ];
    })
  ];

  home-manager.users.${vars.user} = {
    home.stateVersion = "23.11";
    #programs.home-manager.enable = true;
    xdg.userDirs.createDirectories = true;
  };

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets."wifi.env".path ];
    profiles."home-wifi" = {
      connection = {
        id = "$home_ssid";
        type = "wifi";
      };
      ipv4.method = "auto";
      ipv6.method = "disabled";
      wifi = {
        mode = "infrastructure";
        ssid = "$home_ssid";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "$home_psk";
      };
    };
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    optimise.automatic = true;

    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      nixpkgs-stable.flake = inputs.nixpkgs-stable;
    };

    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      trusted-substituters = [
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = [ "@wheel" ];
    };
  };

  programs.dconf.enable = true;

  security = {
    polkit.enable = true;

    sudo = {
      # Rollbacks would result in sudo lectures after each reboot
      extraConfig = ''
        Defaults lecture = never
      '';
      wheelNeedsPassword = true;
    };
  };

  services = {
    btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
      fileSystems = [ "/" "/home" "/nix" ];
    };

    # Enable SSD trim
    fstrim.enable = lib.mkDefault true;

    openssh = {
      enable = true;
      settings = {
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = "${vars.configPath}/secrets/secrets.yaml";
    validateSopsFiles = false;
    secrets = {
      "user/password".neededForUsers = true;
      "wifi.env" = { };
    };
  };

  system.stateVersion = "23.11";

  systemd.services.NetworkManager-wait-online.enable = lib.mkDefault false;

  users = {
    # All users setup via declaration
    mutableUsers = false;

    # Disable root login
    users.root.initialHashedPassword = "!";
    #users.root.shell = "/run/current-system/sw/bin/nologin";

    # Just me using these systems, so user is a variable
    users.${vars.user} = {
      createHome = true;
      description = "${vars.name}";
      extraGroups = [
        "audio"
        "gamemode"
        "input"
        "networkmanager"
        "syncthing"
        "video"
        "wheel"
      ];
      hashedPasswordFile = config.sops.secrets."user/password".path;
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAMoEb31xABf0fovDku5zBfBDI2sKCixc31wndQj5VhT jays@FW13"
      ];
    };
  };

}
