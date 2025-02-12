{
  cfgTerm,
  config,
  inputs,
  lib,
  myUser,
  nixPath,
  pkgs,
  #stable,
  ...
}: let
  userName = "Jason";
  superfile-pkg = inputs.superfile.packages.${pkgs.system}.superfile;
in {
  imports = (
    import ../modules/desktops ++
    import ../modules/hardware ++
    import ../modules/programs
  );

  options.myUser = lib.mkOption {
    default = "jays";
    type = lib.types.str;
  };

  config = {
    myOptions.${cfgTerm}.enable = true;

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
        cryptomator                 # Encrypt cloud files - unstable refuses to build on last flake update
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
        dmidecode                   # Firmware | 'dmidecode -s bios-version'
        ffmpeg-full                 # Hardware video acceleration
        glxinfo                     # OpenGL info
        lm_sensors                  # Hardware sensors | 'sensors-detect'
        lshw                        # Hardware config
        nvme-cli                    # Manage NVMe
        pciutils                    # Manage PCI | 'lspci'
        usbutils                    # Manage USB | 'lsusb'

      # Images
        feh                         # Image viewer
        imagemagick                 # Image tools

      # Monitoring
        btop                        # Resource manager
        htop                        # Resource manager

      # Network
        #cifs-utils                 # SMB support
        dig                         # DNS tools
        nfs-utils                   # NFS support
        nmap                        # Network discovery

      # Nix
        home-manager                # 'programs.home-manager.enable' doesn't install
        nix-tree                    # Browse nix store

      # Notifications
        libnotify                   # Notification engine

      # Productivity
        hunspell                    # Spellcheck
        hunspellDicts.en_US         # US English

      # Secrets
        sops                        # Secret management
        ssh-to-age                  # Convert SSH keys to Age

      # Terminal
        bat                         # cat with syntax highlighting
        chafa                       # Terminal images
        coreutils                   # GNU utilities
        eza                         # ls/tree replacement | 'eza' or 'exa'
        fastfetch                   # Faster system info
        killall                     # Process killer
        shellcheck                  # Script formating checker
        superfile-pkg               # CLI file manager
        tldr                        # Abbreviated manual
        tmux                        # Multiplexor
        toybox                      # Various commands
        tree                        # Directory layout
        wget                        # Retriever
        wl-clipboard                # Enable wl-copy/wl-paste / used in Neovim
        xdg-utils                   # Environment integration
        zellij                      # Tmux alternative

      # Theming
        base16-schemes              # Presets
        #variety                    # Wallpapers
      ];

      variables = {
        EDITOR = "nvim";
        TERMINAL = cfgTerm;
      };
    };

    fonts.packages = with pkgs; [
      cantarell-fonts               # GNOME
    ] ++ (with nerd-fonts; [
      jetbrains-mono
      noto
      symbols-only
    ]);
    
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    home-manager.users.${myUser} = {
      xdg.userDirs.createDirectories = true;
    };

    i18n.defaultLocale = "en_US.UTF-8";

    networking.networkmanager = {
      enable = true;
      ensureProfiles = {
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
        stable.flake = inputs.nixpkgs-stable;
      };
      settings = {
        auto-optimise-store = true;
        #download-buffer-size = 67108864; # Default 67108864
        experimental-features = [
          "flakes"
          "nix-command"
        ];
        substituters = [
          "https://nix-community.cachix.org"
          "https://cosmic.cachix.org/"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
        ];
        trusted-users = [ "@wheel" ];
      };
    };

    nixpkgs = {
      config.allowUnfree = true;
      overlays = [
        inputs.nur.overlays.default
      ];
    };

    programs = {
      dconf.enable = true;
      /*
      direnv = {
        enable = true;
        enableBashIntegration = true;
        nix-direnv.enable = true;
      };*/
    };

    security = {
      polkit.enable = true;
      sudo = {
        extraConfig = ''Defaults lecture = never'';
        wheelNeedsPassword = true;
      };
    };

    services = {
      btrfs.autoScrub = {
        enable = true;
        interval = "weekly";
        fileSystems = [ "/" "/home" "/nix" ];
      };
      # SSD trim
      fstrim.enable = lib.mkDefault true;
      libinput = {
        enable = true;
        touchpad = {
          disableWhileTyping = true;
          tapping = true;
          tappingDragLock = true;
        };
      };
      openssh = {
        enable = true;
        extraConfig = "AllowAgentForwarding yes";
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
      xserver.xkb.layout = "us";
    };

    sops = {
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      defaultSopsFile = "${nixPath}/secrets/secrets.yaml";
      secrets = {
        "user/password".neededForUsers = true;
        "wifi.env" = { };
      };
      validateSopsFiles = false;
    };

    systemd.services.NetworkManager-wait-online.enable = lib.mkDefault false;
    time.timeZone = "America/Chicago";

    users = {
      # All users/passwords setup via declaration
      mutableUsers = false;
      users = {
        ${myUser} = {
          description = "${userName}";
          extraGroups = [
            "adbusers"
            "audio"
            "input"
            "networkmanager"
            "video"
            "wheel"
          ];
          hashedPasswordFile = config.sops.secrets."user/password".path;
          isNormalUser = true;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAMoEb31xABf0fovDku5zBfBDI2sKCixc31wndQj5VhT ${myUser}"
          ];
        };

        root = {
          # Disables root login
          initialHashedPassword = "!";
        };
      };
    };
  };
}
