{ config, inputs, lib, pkgs, stable, vars, ... }: let
  secrets = config.sops.secrets;
  superfile-pkg = inputs.superfile.packages.${pkgs.system}.superfile;
in {
  imports = (
    import ../modules/desktops ++
    import ../modules/hardware ++
    import ../modules/programs
  );

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

    # Files
      exiftool                    # File metadata
      file                        # File information
      libarchive                  # ISO extraction | 'bsdtar -xf IsoFile.iso OutputFile'
      p7zip                       # Zip encryption
      unzip                       # Zip files
      unrar                       # Rar files
      #xdragon                    # Terminal drag'n'drop
      zip                         # Zip files

    # Hardware
      clinfo                      # OpenCL info | 'clinfo -l' or -a
      ffmpeg-full                 # Hardware video acceleration
      lm_sensors                  # Hardware sensors | 'sensors-detect'
      lshw                        # Hardware config
      nvme-cli                    # Manage NVMe
      pciutils                    # Manage PCI | 'lspci'
      usbutils                    # Manage USB | 'lsusb'

    # Images
      feh                         # Image viewer
      imagemagick                 # Image tools
      qview                       # Image viewer

    # Monitoring
      btop                        # Resource manager
      htop                        # Resource manager

    # Network
      #cifs-utils                 # SMB support
      dig                         # DNS tools
      nfs-utils                   # NFS support
      nmap                        # Network discovery

    # Notifications
      libnotify                   # Notification engine

    # Secrets
      sops                        # Secret management
      ssh-to-age                  # Convert SSH keys to Age

    # Terminal
      bat                         # cat with syntax highlighting
      coreutils                   # GNU utilities
      eza                         # ls/tree replacement | 'eza' or 'exa'
      fastfetch                   # Faster system info
      killall                     # Process killer
      nix-tree                    # Browse nix store
      shellcheck                  # Script formating checker
      superfile-pkg               # CLI file manager
      tldr                        # Abbreviated manual
      tmux                        # Multiplexor
      tree                        # Directory layout
      wget                        # Retriever
      wl-clipboard                # Enable wl-copy/wl-paste / used in Neovim
      xdg-utils                   # Environment integration
      zellij                      # Tmux alternative

    # Theming
      #base16-schemes             # Presets
      #variety                    # Wallpapers
    ];

    variables = {
      EDITOR = "nvim";
      TERMINAL = "${vars.terminal}";
    };
  };

  fonts.packages = with pkgs; [
    cantarell-fonts               # GNOME
    (nerdfonts.override {
      fonts = [
        "JetBrainsMono"
        "NerdFontsSymbolsOnly"
        "Noto"
      ];
    })
  ];
  
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  home-manager.users.${vars.user} = {
    home.stateVersion = "23.11";
    #programs.home-manager.enable = true;
    xdg.userDirs.createDirectories = true;
  };

  myOptions = {
    git.ssh.enable = lib.mkDefault true;
    hardware.audio.enable = lib.mkDefault true;
    ${vars.terminal}.enable = true;
  };

  networking.networkmanager = {
    enable = true;
    ensureProfiles = {
      environmentFiles = [ secrets."wifi.env".path ];
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
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = [ "@wheel" ];
    };
  };

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [ inputs.nur.overlay ];
  };

  programs = {
    dconf.enable = true;
    /*direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };*/
    #ssh.startAgent = true;
  };

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
      knownHosts = {
        "FW13".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGQQSTCKMqWNCTIFsND7Da2EUTjYktXX8xNl7Yf4X4At";
        "T1".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPiwqkVHyuJgJAdln6Wg7NXip2awN38aXddPydQhTw18";
        "T450s".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIECb1ohJxet0NfaDOGRGEMVGkTY8sUZQ9t9h3P49g+nj";
      };
      settings = {
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        PubkeyAuthentication = "yes";
        UseDns = true;
      };
    };
  };

  sops = {
    age = {
      #generateKey = true;
      #keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
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
    # All users/passwords setup via declaration
    mutableUsers = false;
    users = {
      # Single-user system, so user is a variable
      ${vars.user} = {
        description = "${vars.name}";
        extraGroups = [
          "audio"
          "input"
          "networkmanager"
          "video"
          "wheel"
        ];
        hashedPasswordFile = secrets."user/password".path;
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAMoEb31xABf0fovDku5zBfBDI2sKCixc31wndQj5VhT ${vars.user}"
        ];
      };

      root = {
        # Disables root login
        initialHashedPassword = "!";
        # Disables 'sudo su'
        #shell = "/run/current-system/sw/bin/nologin";
      };
    };
  };

}
