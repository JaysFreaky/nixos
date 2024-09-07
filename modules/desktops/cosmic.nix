{ config, inputs, lib, pkgs, vars, ... }: let
  cfg = config.myOptions.desktops.cosmic;
  #host = config.myHosts;

  cursor = {
    # Variants: Bibata-(Modern/Original)-(Amber/Classic/Ice)
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    # Sizes: 16 20 22 24 28 32 40 48 56 64 72 80 88 96
    size = 24;
  };
  icon = {
    # Variants: Papirus Papirus-Dark Papirus-Light
    name = "Papirus";
    # Folder color variants: https://github.com/PapirusDevelopmentTeam/papirus-folders
    # adwaita black blue bluegrey breeze brown carmine cyan darkcyan deeporange
    # green grey indigo magenta nordic orange palebrown paleorange pink red
    # teal violet white yaru yellow
    package = pkgs.papirus-icon-theme.override { color = "violet"; };
  };
  profileImg = ../../assets/profile.png;
  wallpaper = {
    day = "${vars.configPath}/assets/wallpapers/blobs-l.png";
    night = "${vars.configPath}/assets/wallpapers/blobs-d.png";
  };
in {
  options.myOptions.desktops.cosmic.enable = lib.mkEnableOption "Cosmic desktop";

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [
      cursor.package              # For GDM login screen
      icon.package                # Icon theme
      libsecret                   # Secret storage used by gnome-keyring / KDE-wallet
      neovide                     # GUI launcher for neovim
    ];

    nix.settings = {
      substituters = [ "https://cosmic.cachix.org/" ];
      trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
    };

    services = {
      desktopManager.cosmic.enable = true;
      displayManager.cosmic-greeter.enable = true;

      libinput = {
        enable = true;
        touchpad = {
          disableWhileTyping = true;
          tapping = true;
          tappingDragLock = true;
        };
      };

      xserver = {
        enable = true;
        xkb.layout = "us";
        excludePackages = with pkgs; [ xterm ];
      };
    };

    home-manager.users.${vars.user} = {
      # Sets profile image
      home.file.".face".source = profileImg;

      programs = {
        # Set terminal themes
        #alacritty.settings.import = [ "/home/${vars.user}/.config/alacritty/current-theme.toml" ];
        #kitty.extraConfig = ''include /home/${vars.user}/.config/kitty/current-theme.conf'';
      };

      # Set default applications
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          #"image/gif" = [ "org.kde.gwenview.desktop" ];
          #"image/jpg" = [ "org.kde.gwenview.desktop" ];
          #"image/png" = [ "org.kde.gwenview.desktop" ];
          #"text/plain" = [ "neovide.desktop" ];
        };
      };
    };

  };
}
