{ config, host, lib, pkgs, vars, ... }: with lib; let
  wallpaper = {
    dir = "${vars.configPath}/assets/wallpapers";
    regreet = "${wallpaper.dir}/blobs-l.png";
  };
in {
  imports = [
    ./hyprland.nix
    ./waybar.nix
  ];

  options = {
    hyprland.enable = mkOption {
      default = false;
      description = "Enable the Hyprland environment.";
      type = types.bool;
    };
    hyprApps = mkOption {
      description = "Bins for Hyprland environment.";
      type = types.attrs;
    };
  };

  config = mkIf (config.hyprland.enable) {
    hyprApps = {
      blueman = getExe' pkgs.blueman "blueman-manager";
      brightnessctl = getExe pkgs.brightnessctl;
      btop = getExe pkgs.btop;
      cliphist = getExe pkgs.cliphist;
      fileManager = getExe pkgs.pcmanfm;
      firefox = getExe pkgs.firefox;
      grim = getExe pkgs.grim;
      hyprland = getExe pkgs.hyprland;
      nm-applet = getExe' pkgs.networkmanagerapplet "nm-applet";
      nm-connect = getExe' pkgs.networkmanagerapplet "nm-connection-editor";
      nvtop = getExe pkgs.nvtopPackages.nvidia;
      nwg-bar = getExe pkgs.nwg-bar;
      pw-volume = getExe pkgs.pw-volume;
      slurp = getExe pkgs.slurp;
      swww = getExe pkgs.swww;
      swww-daemon = getExe' pkgs.swww "swww-daemon";
      terminal = getExe pkgs.${vars.terminal};
      thunderbird = getExe pkgs.thunderbird;
      tuigreet =  getExe pkgs.greetd.tuigreet;
      waybar = getExe config.programs.waybar.package;
      wl-copy = getExe' pkgs.wl-clipboard "wl-copy";
      wofi = getExe pkgs.wofi;
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
          GDK_SCALE = host.resScale;
          QT_AUTO_SCREEN_SCALE_FACTOR = host.resScale;
        
        # Toolkit Backend
          GDK_BACKEND = "wayland,x11";
          QT_QPA_PLATFORM = "wayland;xcb";

        # Cursor
          HYPRCURSOR_SIZE = 24;
          HYPRCURSOR_THEME = "Bibata-Modern-Classic";
          XCURSOR_SIZE = 24;
          XCURSOR_THEME = "Bibata-Modern-Classic";

        # Theming
          #GTK_THEME = "Catppuccin-Frappe-Standard-Mauve-Dark";
          #QT_QPA_PLATFORMTHEME = "Catppuccin-Frappe-Standard-Mauve-Dark";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
      };

      systemPackages = with pkgs; [
        # Application Launcher
          #rofi-wayland             #
          wofi                      # Launcher
          #iw                       # wireless config for rofi-wifi script
          #bc                       # calculator for rofi-wifi script

        # Authorization Agent
          polkit_gnome              #

        # Clipboard
          cliphist                  # Save clipboard history after closing apps

        # File Manager
          file-roller               # Gnome's GUI archive manager
          pcmanfm                   # Independent file manager

        # Hardware
          brightnessctl             # Laptop monitor brightness control
          pw-volume                 # Pipewire audio control

        # Locking
          #swayidle                 #
          #swaylock-effects         #

        # Login Manager
          greetd.tuigreet           # TTY-like greeter

        # Screenshot
          grim                      #
          slurp                     #

        # Session Management
          nwg-bar                   #
          wlogout                   #

        # Status bar
          #eww-wayland              #
          networkmanagerapplet      # Show network tray icon (nm-applet --indicator)

        # Theming
          pywal                     # Theme colors from current wallpaper
          #wpgtk                    # Pywal GUI

        # Wallpaper
          #hyprpapr                 #
          swww                      # Wallpaper manager capable of GIFs

        # Wayland
          libsForQt5.qt5.qtwayland  # QT5 Wayland support
          qt6.qtwayland             # QT6 Wayland support
          wayland-protocols         # Wayland protocol extensions
          wayland-utils             # Wayland utilities | 'wayland-info'
          wev                       # Keymapper
          wlroots                   # Wayland compositor library
          xwayland                  # Interface X11 apps with Wayland
      ];
    };

    home-manager.users.${vars.user} = { lib, ... }: {
      gtk = {
        enable = true;
        cursorTheme = {
          # Variants: Bibata-(Modern/Original)-(Amber/Classic/Ice)
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          # Sizes: 16 20 22 24 28 32 40 48 56 64 72 80 88 96
          size = 24;
        };
        iconTheme = {
          # Variants: Papirus Papirus-Dark Papirus-Light
          name = "Papirus";
          # Folder color variants: https://github.com/PapirusDevelopmentTeam/papirus-folders
          # adwaita black blue bluegrey breeze brown carmine cyan darkcyan deeporange
          # green grey indigo magenta nordic orange palebrown paleorange pink red
          # teal violet white yaru yellow
          package = pkgs.papirus-icon-theme.override { color = "violet"; };
        };
        #theme = {
          #name = "";
          #package = "";
        #};
      };

      home.pointerCursor = {
        gtk.enable = true;
        # x11.enable = true;
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 24;
      };

      # Use Pywal for terminal theming
      programs = {
        alacritty.settings.import = [ "/home/${vars.user}/.cache/wal/colors-alacritty.toml" ];
        bash.initExtra = ''
          if command -v wal > /dev/null 2>&1 && [ "$TERM" = "${vars.terminal}" ]; then
            wal -Rqe
          fi
        '';
        kitty.extraConfig = ''include /home/${vars.user}/.cache/wal/colors-kitty.conf'';
      };

      #qt.enable = true;

      services = {
        mako.enable = true;
      };

      # Create hyprland pywal template
      xdg.configFile."wal/templates/colors-hyprland.conf".text = ''
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
          cursor_theme_name = "Bibata-Modern-Classic"
          font_name = "Cantarell 16"
          icon_theme_name = "Papirus-Dark"
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
        package = pkgs.greetd.tuigreet;
        settings = let
          hyprApps = config.hyprApps;
        in rec {
          # Auto login
          default_session = initial_session;
          initial_session = {
            # Regreet command
            #command = "${hyprApps.hyprland}";
            # Tuigreet command
            command = "${hyprApps.tuigreet} --asterisks --remember --remember-user-session --time --cmd ${hyprApps.hyprland}";
            user = "${vars.user}";
          };
        };
      };

      hypridle = {
        enable = true;
        package = pkgs.hypridle;
      };

      xserver.excludePackages = with pkgs; [
        xterm
      ];
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
      wlr.enable = true;
    };

  };
}
