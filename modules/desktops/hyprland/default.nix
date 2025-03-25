{
  config,
  lib,
  pkgs,
  cfgHosts,
  cfgOpts,
  cfgTerm,
  myUser,
  nixPath,
  ...
}: let
  cfg = cfgOpts.desktops.hyprland;

  cursor = {
    # Variants: Bibata-(Modern/Original)-(Amber/Classic/Ice)
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    # Sizes: 16 20 22 24 28 32 40 48 56 64 72 80 88 96
    size = 24;
  };
  icon = {
    # Variants: Papirus Papirus-Dark Papirus-Light
    name = "Papirus-Dark";
    # Folder color variants: https://github.com/PapirusDevelopmentTeam/papirus-folders
    # adwaita black blue bluegrey breeze brown carmine cyan darkcyan deeporange
    # green grey indigo magenta nordic orange palebrown paleorange pink red
    # teal violet white yaru yellow
    package = pkgs.papirus-icon-theme.override { color = "violet"; };
  };
  wallpaper = {
    dir = "${nixPath}/assets/wallpapers";
    regreet = "${wallpaper.dir}/blobs-l.png";
  };
in {
  imports = [
    ./hyprland.nix
    ./waybar.nix
  ];

  options.myOptions.desktops.hyprland = {
    enable = lib.mkEnableOption "Hyprland desktop";
    hyprApps = lib.mkOption {
      description = "Bins for Hyprland";
      type = lib.types.attrs;
    };
  };

  config = lib.mkIf (cfg.enable) {
    myOptions.desktops.hyprland.hyprApps = {
      blueman = lib.getExe' pkgs.blueman "blueman-manager";
      brightnessctl = lib.getExe pkgs.brightnessctl;
      btop = lib.getExe pkgs.btop;
      cliphist = lib.getExe pkgs.cliphist;
      fileManager = lib.getExe pkgs.pcmanfm;
      firefox = lib.getExe pkgs.firefox;
      grim = lib.getExe pkgs.grim;
      hyprland = lib.getExe pkgs.hyprland;
      nm-applet = lib.getExe' pkgs.networkmanagerapplet "nm-applet";
      nm-connect = lib.getExe' pkgs.networkmanagerapplet "nm-connection-editor";
      nvtop = lib.getExe pkgs.nvtopPackages.nvidia;
      nwg-bar = lib.getExe pkgs.nwg-bar;
      pw-volume = lib.getExe pkgs.pw-volume;
      slurp = lib.getExe pkgs.slurp;
      swww = lib.getExe pkgs.swww;
      swww-daemon = lib.getExe' pkgs.swww "swww-daemon";
      terminal = lib.getExe pkgs.${cfgTerm};
      thunderbird = lib.getExe pkgs.thunderbird;
      tuigreet =  lib.getExe pkgs.greetd.tuigreet;
      waybar = lib.getExe config.programs.waybar.package;
      wl-copy = lib.getExe' pkgs.wl-clipboard "wl-copy";
      wofi = lib.getExe pkgs.wofi;
    };

    environment = {
      sessionVariables = {
        # Hint electron apps to use Wayland
          NIXOS_OZONE_WL = 1;
        # VMware?
          WLR_RENDERER_ALLOW_SOFTWARE = 1;

        # XDG
          XDG_CURRENT_DESKTOP = "Hyprland";
          XDG_SESSION_DESKTOP = "Hyprland";
          XDG_SESSION_TYPE = "wayland";

        # Scaling
          GDK_SCALE = cfgHosts.scale;
          QT_AUTO_SCREEN_SCALE_FACTOR = cfgHosts.scale;
        
        # Toolkit Backend
          GDK_BACKEND = "wayland,x11";
          QT_QPA_PLATFORM = "wayland;xcb";

        # Cursor
          HYPRCURSOR_SIZE = cursor.size;
          HYPRCURSOR_THEME = cursor.name;
          XCURSOR_SIZE = cursor.size;
          XCURSOR_THEME = cursor.name;

        # Theming
          #GTK_THEME = "Catppuccin-Frappe-Standard-Mauve-Dark";
          #QT_QPA_PLATFORMTHEME = "Catppuccin-Frappe-Standard-Mauve-Dark";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
      };

      systemPackages = builtins.attrValues {
        inherit (pkgs)
        # Application Launcher
          #rofi-wayland           #
          wofi                    # Launcher
          #iw                     # wireless config for rofi-wifi script
          #bc                     # calculator for rofi-wifi script

        # Authorization Agent
          polkit_gnome            #

        # Clipboard
          cliphist                # Save clipboard history after closing apps

        # File Manager
          file-roller             # Gnome's GUI archive manager
          pcmanfm                 # Independent file manager

        # Hardware
          brightnessctl           # Laptop monitor brightness control
          pw-volume               # Pipewire audio control

        # Locking
          #swayidle               #
          #swaylock-effects       #

        # Screenshot
          grim                    #
          slurp                   #

        # Session Management
          nwg-bar                 #
          wlogout                 #

        # Status bar
          #eww-wayland            #
          networkmanagerapplet    # Show network tray icon (nm-applet --indicator)

        # Theming
          pywal                   # Theme colors from current wallpaper
          #wpgtk                  # Pywal GUI

        # Wallpaper
          #hyprpapr               #
          swww                    # Wallpaper manager capable of GIFs

        # Wayland
          wayland-protocols       # Wayland protocol extensions
          wayland-utils           # Wayland utilities | 'wayland-info'
          wev                     # Keymapper
          wlroots                 # Wayland compositor library
          xwayland                # Interface X11 apps w/ Wayland
        ;
      } ++ [
        # Display Manager
        pkgs.greetd.tuigreet            # TTY-like greeter

        # Wayland
        pkgs.kdePackages.qtwayland      # QT6 Wayland support
        pkgs.libsForQt5.qt5.qtwayland   # QT5 Wayland support
      ];
    };

    fonts.packages = builtins.attrValues {
      inherit (pkgs)
        font-awesome    # Icons
        inter           # Waybar
      ;
    };

    home-manager.users.${myUser} = { lib, ... }: {
      gtk = {
        enable = true;
        cursorTheme = {
          name = cursor.name;
          package = cursor.package;
          size = cursor.size;
        };
        iconTheme = {
          name = icon.name;
          package = icon.package;
        };
        #theme = {
          #name = "";
          #package = "";
        #};
      };

      home.pointerCursor = {
        gtk.enable = true;
        # x11.enable = true;
        package = cursor.package;
        name = cursor.name;
        size = cursor.size;
      };

      # Use Pywal for terminal theming
      programs = {
        bash.initExtra = ''
          if command -v wal > /dev/null 2>&1 && [ "$TERM" = "${cfgTerm}" ]; then
            wal -Rqe
          fi
        '';
        kitty.extraConfig = ''include /home/${myUser}/.cache/wal/colors-kitty.conf'';
      };

      #qt.enable = true;

      services = {
        mako.enable = true;
      };

      xdg = {
        # Create hyprland pywal template
        configFile."wal/templates/colors-hyprland.conf".text = ''
          $background = rgb({background.strip})
          $foreground = rgb({foreground.strip})
          $color0 = rgb({color0.strip})
          $color1 = rgb({color1.strip})
          $color2 = rgb({color2.strip})
          $color3 = rgb({color3.strip})
          $color4 = rgb({color4.strip})
          $color5 = rgb({color5.strip})
          $color6 = rgb({color6.strip})
          $color7 = rgb({color7.strip})
          $color8 = rgb({color8.strip})
          $color9 = rgb({color9.strip})
          $color10 = rgb({color10.strip})
          $color11 = rgb({color11.strip})
          $color12 = rgb({color12.strip})
          $color13 = rgb({color13.strip})
          $color14 = rgb({color14.strip})
          $color15 = rgb({color15.strip})
        '';

        # Set default application file associations
        mimeApps = let
          mime = {
            archive = [
              #"org.kde.ark.desktop"
            ];
            audio = [ "" ];
            calendar = [ "" ];
            image = [ "feh.desktop" ];
            pdf = [ "${cfgOpts.browser}.desktop" ];
            text = [ "neovide.desktop" ];
            video = [ "" ];
          };
        in {
          enable = true;
          associations.added = config.xdg.mimeApps.defaultApplications;
          defaultApplications = import ../mimeapps.nix { inherit mime; };
        };
      };
    };

    programs = {
      hyprland = {
        enable = true;
        # X11 compatability
        xwayland.enable = true;
      };

      hyprlock = {
        enable = true;
        package = pkgs.hyprlock;
      };

      regreet = {
        enable = false;
        settings = ''
          [background]
          path = "${wallpaper.regreet}"
          # Available values: "Fill", "Contain", "Cover", "ScaleDown"
          fit = "Contain"

          [commands]
          reboot = [ "systemctl", "reboot" ]
          poweroff = [ "systemctl", "poweroff" ]

          [env]
          #ENV_VARIABLE = "value"

          [GTK]
          application_prefer_dark_theme = true
          cursor_theme_name = "${cursor.name}"
          font_name = "Cantarell 16"
          icon_theme_name = "${icon.name}"
          #theme_name = ""
        '';
      };
    };

    security = {
      # Enable keyboard input after locking
      #pam.services.swaylock = {};
      pam.services.hyprlock = {};
      polkit.enable = true;
    };

    services = {
      dbus.enable = true;

      greetd = {
        enable = true;
        package = lib.mkIf (!config.programs.regreet.enable) pkgs.greetd.tuigreet;
        settings = let
          hyprApps = cfg.hyprApps;
        in {
          # Auto login
          default_session = config.services.greetd.settings.initial_session;
          initial_session = {
            command = if (config.programs.regreet.enable)
              # Regreet
              then "${hyprApps.hyprland}"
              # Tuigreet
              else "${hyprApps.tuigreet} --asterisks --remember --remember-user-session --time --cmd ${hyprApps.hyprland}";
            user = myUser;
          };
        };
      };

      hypridle = {
        enable = true;
        package = pkgs.hypridle;
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      wlr.enable = true;
    };
  };
}
