{ config, inputs, lib, pkgs, stable, vars, ... }:
with lib;
{
  imports = (
    import ../modules/desktops ++
    import ../modules/hardware ++
    import ../modules/persist ++
    import ../modules/programs
  );

  ${vars.terminal}.enable = true;

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
      asciiquarium          # Fishies swimming
      cbonsai               # Bonsai growing

    # Browsers
      #floorp               # Privacy-focused Firefox fork

    # File Support
      #cifs-utils           # SMB support
      imagemagick           # Image tools
      nfs-utils             # NFS support
      p7zip                 # Zip encryption
      qview                 # Image viewer
      unzip                 # Zip files
      unrar                 # Rar files
      zip                   # Zip files

    # Messaging
      discord               # Discord

    # Multimedia
      mpv                   # Media player
      plex-media-player     # Plex player
      spotify               # Music

    # Notes
      obsidian              # Markdown notes

    # Notifications
      libnotify             # Notification engine

    # Terminal
      bat                   # cat with syntax highlighting
      btop                  # Resource manager
      coreutils             # GNU utilities
      fastfetch             # Faster system info
      file                  # File information
      killall               # Process killer
      lm_sensors            # Hardware sensors | 'sensors-detect'
      lshw                  # Hardware config
      neofetch              # System info
      nix-tree              # Browse nix store
      pciutils              # Manage PCI | 'lspci'
      #${vars.terminal}     # Terminal installed via variable
      tldr                  # Helper
      tmux                  # Multiplexor
      tree                  # Directory layout
      usbutils              # Manage USB | 'lsusb'
      vim                   # Editor
      wget                  # Retriever
      xdg-utils             # Environment integration
      xdragon               # Terminal drag'n'drop
      #zellij               # Tmux alternative

    # Theming
      pywal                 # System theme colors based off current wallpaper
      pywalfox-native       # Firefox integration
      spicetify-cli         # Spotify theming
      #variety              # Wallpapers
      #wpgtk                # Pywal GUI
    ];
  };

  fonts.packages = with pkgs; [
    cantarell-fonts         # GNOME
    font-awesome            # Icons
    inter                   # Good for Waybar
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
      trusted-users = [ "@wheel" ];

      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  programs.dconf.enable = true;

  security = {
    polkit.enable = true;

    sudo = {
      # TmpFS/rollbacks result in sudo lectures after each reboot
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
      fileSystems = [ "/home" "/nix" "/persist" "/var/log" ];
    };

    # Enable SSD trim
    fstrim.enable = mkDefault true;

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

  systemd.services.NetworkManager-wait-online.enable = mkDefault false;

  users = {
    # All users setup via declaration
    mutableUsers = false;

    # Disable root login
    users.root.initialHashedPassword = "!";
    #users.root.shell = "/run/current-system/sw/bin/nologin";

    # Just me using this system, so user is dynamic
    users.${vars.user} = {
      createHome = true;
      description = "${vars.name}";
      extraGroups = [ "audio" "gamemode" "input" "networkmanager" "syncthing" "video" "wheel" ];
      hashedPasswordFile = "/persist/etc/users/${vars.user}";
      isNormalUser = true;
    };
  };

}
