{ config, lib, pkgs, stable, vars, ... }:
let
  pywalfox = pkgs.python3.pkgs.buildPythonPackage {
    pname = "pywalfox";
    version = "2.8.0rc1";
    src = pkgs.fetchFromGitHub {
      owner = "Frewacom";
      repo = "pywalfox-native";
      rev = "7ecbbb193e6a7dab424bf3128adfa7e2d0fa6ff9";
      hash = "sha256-i1DgdYmNVvG+mZiFiBmVHsQnFvfDFOFTGf0GEy81lpE=";
    };
  };
in {
  imports = (
    import ../modules/desktops ++
    import ../modules/hardware ++
    import ../modules/persist ++
    import ../modules/programs
  );

  ${vars.terminal}.enable = true;

  # Prioritize swap for hibernation only
  boot.kernel.sysctl."vm.swappiness" = lib.mkDefault 0;

  console = {
    #font = "Lat2-Terminus16";
    keyMap = "us";
  };

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Chicago";

  environment = {
    variables = {
      TERMINAL = "${vars.terminal}";
      EDITOR = "${vars.editor}";
    };

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    # To use a stable version, add 'stable.' to the beginning of the package:
    # stable.wget
    systemPackages = with pkgs; [
    # ASCII Art
      asciiquarium                # Fishies swimming
      cbonsai                     # Bonsai growing

    # Browsers
      #floorp                     # Privacy-focused Firefox fork

    # File Support
      #cifs-utils                 # SMB support
      imagemagick                 # Image tools
      nfs-utils                   # NFS support
      p7zip                       # Zip encryption
      qview                       # Image viewer
      unzip                       # Zip files
      unrar                       # Rar files
      zip                         # Zip files

    # Messaging
      discord                     # Discord

    # Multimedia
      mpv                         # Media player
      plex-media-player           # Plex player
      spotify                     # Music

    # Notes
      obsidian                    # Markdown notes

    # Notifications
      libnotify                   # Notification engine

    # Terminal
      bat                         # cat with syntax highlighting
      btop                        # Resource manager
      coreutils                   # GNU utilities
      fastfetch                   # Faster system info
      file                        # File information
      killall                     # Process killer
      lm_sensors                  # Hardware sensors | 'sensors-detect'
      lshw                        # Hardware config
      neofetch                    # System info
      nix-tree                    # Browse nix store
      pciutils                    # Manage PCI | 'lspci'
      #${vars.terminal}           # Terminal installed via variable
      tldr                        # Helper
      tmux                        # Multiplexor
      tree                        # Directory layout
      usbutils                    # Manage USB | 'lsusb'
      vim                         # Editor
      wget                        # Retriever
      wl-clipboard                # Enable wl-copy/wl-paste / used in Neovim
      xdg-utils                   # Environment integration
      xdragon                     # Terminal drag'n'drop
      #zellij                     # Tmux alternative

    # Theming
      pywal                       # Theme colors from current wallpaper
      (python3.withPackages (ps: with ps; [
        pip virtualenv pywalfox   # pywalfox-native NixOS fix
      ]))
      spicetify-cli               # Spotify theming
      #variety                    # Wallpapers
      #wpgtk                      # Pywal GUI
    ];
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
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
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
      fileSystems = [ "/" "/home" "/nix" "/persist" "/var/log" ];
    };

    # Enable SSD trim
    fstrim.enable = lib.mkDefault true;

    # SSHing into these systems is disabled, but can still SSH out
    openssh = {
      enable = false;
      #knownHosts.<name>.publicKeyFile = "";

      hostKeys = [
        {
          path = "/persist/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "/persist/ssh/ssh_host_rsa_key";
          type = "rsa";
          bits = 4096;
        }
      ];

      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
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

    # Only me using these systems, so user is a variable
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
      hashedPasswordFile = "/persist/etc/users/${vars.user}";
      isNormalUser = true;
    };
  };

}
