{ config, lib, pkgs, vars, ... }:
with lib;
let
  day_cw = pkgs.writeShellScriptBin "day_cw.sh" ''
    day=$(gsettings get org.gnome.desktop.background picture-uri | cut -d "'" -f2 | cut -c 8-)
    wal -nqsti "$day"
    pywalfox update
    pywalfox light
  '';
  night_cw = pkgs.writeShellScriptBin "night_cw.sh" ''
    night=$(gsettings get org.gnome.desktop.background picture-uri-dark | cut -d "'" -f2 | cut -c 8-)
    wal -nqsti "$night"
    pywalfox update
    pywalfox dark
  '';
in {
  options.gnome.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.gnome.enable) {
    environment = {
      # System-Wide Packages
      systemPackages = with pkgs; [
        gnome.dconf-editor            # GUI dconf editor
        gnome.gnome-tweaks            # Gnome tweaks
        gnome.nautilus-python         # Allow custom nautilus scripts/open-any-terminal
        gnome-extension-manager       # Gnome extensions
        #gradience                    # Monet window theming
        libappindicator               # Allow tray icons to be displayed in GNOME
        libsecret                     # Secret storage used by gnome-keyring / KDE-wallet
        nautilus-open-any-terminal    # Open custom terminals in nautilus
        neovide                       # GUI launcher for neovim
      ];
      # Removed Packages
      gnome.excludePackages = (with pkgs; [
        #gnome-photos               # Image viewer
        gnome-tour                  # Setup walkthrough
      ]) ++ (with pkgs.gnome; [
        cheese                      # "fun" webcam app
        epiphany                    # Web browser
        #evince                     # Document viewer
        geary                       # Email client
        #gedit                      # Text editor
        gnome-characters            # Character map
        gnome-contacts              # Contact app
        gnome-initial-setup         # First time setup
        #gnome-maps                 # Maps
        gnome-music                 # Music
        #gnome-terminal             # Console
        simple-scan                 # Scanning app
        #snapshot                   # Webcam
        totem                       # Video player
        yelp                        # Help
      ]);
    };

    # Manages keys/passwords in gnome-keyring
    programs.seahorse.enable = true;

    # Unlock keyring upon logon
    security.pam.services.gdm.enableGnomeKeyring = true;

    services = {
      # Manages keys/passwords in gnome-keyring
      dbus.packages = [ pkgs.gnome.seahorse ];

      # Auto login can be enabled because LUKS is setup
      # However, this will prevent the keyring from unlocking
      displayManager.autoLogin = {
        enable = mkDefault false;
        user = "${vars.user}";
      };

      # Remove all games instead of individually above
      gnome.games.enable = false;

      gnome.gnome-keyring.enable = true;

      xserver = {
        enable = true;
        desktopManager.gnome.enable = true;
        displayManager.gdm.enable = true;

        excludePackages = with pkgs; [
          xterm
        ];

        libinput = {
          enable = true;
          touchpad = {
            disableWhileTyping = true;
            tapping = true;
            tappingDragLock = true;
          };
        };

        xkb = {
          layout = "us";
        };
      };

      # Enable additional systray icons
      udev.packages = with pkgs; [
        gnome.gnome-settings-daemon
      ];
    };

    systemd = {
      services = {
        # These fix current autologin issues with Gnome
        "getty@tty1".enable = false;
        "autovt@tty1".enable = false;
      };
    };
 
    home-manager.users.${vars.user} = { config, lib, ... }: {
      dconf.settings = {
        "ca/desrt/dconf-editor" = {
          show-warning = false;
        };
        "com/github/stunkymonkey/nautilus-open-any-terminal" = {
          new-tab = true;
          terminal = "${vars.terminal}";
        };
        "org/gnome/desktop/interface" = {
          clock-show-date = true;
          clock-show-weekday = true;
          #color-scheme = "prefer-dark";
          enable-hot-corners = false;
          font-antialiasing = "rgba";
          show-battery-percentage = true;
        };
        "org/gnome/desktop/peripherals/touchpad" = {
          tap-to-click = true;
          two-finger-scrolling-enabled = true;
        };
        "org/gnome/desktop/privacy" = {
          disable-camera = true;
          disable-microphone = true;
          old-files-age = lib.hm.gvariant.mkUint32 7;
          recent-files-max-age = -1;
          remember-recent-files = false;
          remove-old-temp-files = true;
          report-technical-problems = "false";
        };
        "org/gnome/desktop/session" = {
          idle-delay = lib.hm.gvariant.mkUint32 300;
        };
        "org/gnome/desktop/wm/keybindings" = {
          close = [ "<Super>q" ];
          maximize = [];
          minimize = [];
          move-to-monitor-down = [];
          move-to-monitor-left = [];
          move-to-monitor-right = [];
          move-to-monitor-up = [];
          move-to-workspace-1 = [ "<Shift><Super>1" ];
          move-to-workspace-2 = [ "<Shift><Super>2" ];
          move-to-workspace-3 = [ "<Shift><Super>3" ];
          move-to-workspace-4 = [ "<Shift><Super>4" ];
          switch-applications = [ "<Super>Tab" "<Alt>Tab" ];
          switch-applications-backward = [ "<Shift><Super>Tab" "<Shift><Alt>Tab" ];
          switch-group = [ "<Super>Above_Tab" "<Alt>Above_Tab" ];
          switch-group-backward = [ "<Shift><Super>Above_Tab" "<Shift><Alt>Above_Tab" ];
          switch-input-source = [];
          switch-input-source-backward = [];
          switch-to-workspace-1 = [ "<Super>1" ];
          switch-to-workspace-2 = [ "<Super>2" ];
          switch-to-workspace-3 = [ "<Super>3" ];
          switch-to-workspace-4 = [ "<Super>4" ];
          switch-to-workspace-last = [ "<Super>End" ];
          switch-to-workspace-left = [ "<Super>Page_Up" "<Super><Alt>Left" "<Control><Alt>Left" ];
          switch-to-workspace-right = [ "<Super>Page_Down" "<Super><Alt>Right" "<Control><Alt>Right" ];
          toggle-fullscreen = [ "<Shift><Super>f" ];
          unmaximize = [];
        };
        "org/gnome/desktop/wm/preferences" = {
          button-layout = "appmenu:minimize,maximize,close";
          focus-mode = "sloppy";
          mouse-button-modifier = "<Alt>";
          workspace-names = [];
        };
        "org/gnome/mutter" = {
          center-new-windows = true;
          edge-tiling = false;
          # Adds 1.25 scaling option under Display
          experimental-features = [ "scale-monitor-framebuffer" ];
          workspaces-only-on-primary = false;
        };
        "org/gnome/mutter/keybindings" = {
          cancel-input-capture = [ "<Super><Shift>Escape" ];
          toggle-tiled-left = [];
          toggle-tiled-right = [];
        };
        "org/gnome/mutter/wayland/keybindings" = {
          restore-shortcuts = [];
        };
        "org/gnome/nautilus/preferences" = {
          always-use-location-entry = false;
        };
        "org/gnome/settings-daemon/plugins/media-keys" = {
          custom-keybindings = [
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
          ];
          help = [];
          home = [];
          magnifier = [];
          magnifier-zoom-in = [];
          magnifier-zoom-out = [];
          rotate-video-lock-static = [ "<Super>o" "XF86RotationLockToggle" ];
          screenreader = [];
          screensaver = [ "<Super>l" ];
          www = [ "<Super>w" ];
        };
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          binding = "<Super>Return";
          command = "${vars.terminal}";
          name = "Launch Terminal";
        };
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
          binding = "<Super>e";
          command = "nautilus";
          name = "Launch File Manager";
        };
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
        };
        "org/gnome/shell" = {
          enabled-extensions = [
            "drive-menu@gnome-shell-extensions.gcampax.github.com"
            "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
            "user-theme@gnome-shell-extensions.gcampax.github.com"
            "AlphabeticalAppGrid@stuarthayhurst"
            "appindicatorsupport@rgcjonas.gmail.com"
            "bluetooth-quick-connect@bjarosze.gmail.com"
            "blur-my-shell@aunetx"
            "clipboard-indicator@tudmotu.com"
            "forge@jmmaranan.com"
            "just-perfection-desktop@just-perfection"
            "lockkeys@vaina.lt"
            "nightthemeswitcher@romainvigier.fr"
            "pip-on-top@rafostar.github.com"
            "power-profile-switcher@eliapasquali.github.io"
            "Vitals@CoreCoding.com"
            "weatherornot@somepaulo.github.io"
          ];
          disable-user-extensions = false;
          favorite-apps = [
            "Alacritty.desktop"
            "kitty.desktop"
            "org.gnome.Nautilus.desktop"
            "firefox.desktop"
            "floorp.desktop"
            "spotify.desktop"
            "discord.desktop"
            "steam.desktop"
            "plexmediaplayer.desktop"
            #"org.gnome.Settings.desktop"
          ];
        };
        "org/gnome/shell/extensions/appindicator" = {
          icon-size = 16;
        };
        "org/gnome/shell/extensions/bluetooth-quick-connect" = {
          bluetooth-auto-power-off = true;
          bluetooth-auto-power-off-interval = 180;
          refresh-button-on = true;
          show-battery-icon-on = true;
          show-battery-value-on = true;
        };
        "org/gnome/shell/extensions/blur-my-shell" = {
          hacks-level = 3;
        };
        "org/gnome/shell/extensions/blur-my-shell/applications" = {
          blur = true;
          blur-on-overview = true;
          customize = true;
          opacity = 255;
          sigma = 8;
          whitelist = [ "Alacritty" "kitty" ];
        };
        "org/gnome/shell/extensions/blur-my-shell/panel" = {
          blur = true;
          brightness = 1.0;
          customize = true;
          override-background = true;
          static-blur = true;
          style-panel = 0;
          unblur-in-overview = true;
        };
        "org/gnome/shell/extensions/clipboard-indicator" = {
          clear-on-boot = true;
          strip-text = true;
          topbar-preview-size = 10;
        };
        "org/gnome/shell/extensions/forge" = {
          css-last-update = lib.hm.gvariant.mkUint32 37;
          css-updated = "1702937809549";
          dnd-center-layout = "stacked";
          focus-border-toggle = true;
          preview-hint-enabled = true;
          stacked-tiling-mode-enabled = false;
          tabbed-tiling-mode-enabled = false;
          tiling-mode-enabled = true;
          window-gap-hidden-on-single = true;
          window-gap-size = lib.hm.gvariant.mkUint32 3;
          window-gap-size-increment = lib.hm.gvariant.mkUint32 1;
          workspace-skip-tile = "";
        };
        "org/gnome/shell/extensions/forge/keybindings" = {
          con-split-horizontal = [];
          con-split-layout-toggle = [ "<Super>j" ];
          con-split-vertical = [];
          con-stacked-layout-toggle = [];
          con-tabbed-layout-toggle = [];
          con-tabbed-showtab-decoration-toggle = [];
          focus-border-toggle = [];
          prefs-tiling-toggle = [];
          window-focus-down = [ "<Super>down" ];
          window-focus-left = [ "<Super>left" ];
          window-focus-right = [ "<Super>right" ];
          window-focus-up = [ "<Super>up" ];
          window-gap-size-decrease = [ "<Control><Super>minus" ];
          window-gap-size-increase = [ "<Control><Super>plus" ];
          window-move-down = [ "<Shift><Super>down" ];
          window-move-left = [ "<Shift><Super>left" ];
          window-move-right = [ "<Shift><Super>right" ];
          window-move-up = [ "<Shift><Super>up" ];
          window-resize-bottom-decrease = [ "<Shift><Control><Super>u" ];
          window-resize-bottom-increase = [ "<Control><Super>u" ];
          window-resize-left-decrease = [ "<Shift><Control><Super>y" ];
          window-resize-left-increase = [ "<Control><Super>y" ];
          window-resize-right-decrease = [ "<Shift><Control><Super>o" ];
          window-resize-right-increase = [ "<Control><Super>o" ];
          window-resize-top-decrease = [ "<Shift><Control><Super>i" ];
          window-resize-top-increase = [ "<Control><Super>i" ];
          window-snap-center = [ "<Control><Alt>c" ];
          window-snap-one-third-left = [ "<Control><Alt>d" ];
          window-snap-one-third-right = [ "<Control><Alt>g" ];
          window-snap-two-third-left = [ "<Control><Alt>e" ];
          window-snap-two-third-right = [ "<Control><Alt>t" ];
          window-swap-down = [ "<Control><Super>down" ];
          window-swap-last-active = [];
          window-swap-left = [ "<Control><Super>left" ];
          window-swap-right = [ "<Control><Super>right" ];
          window-swap-up = [ "<Control><Super>up" ];
          window-toggle-always-float = [ "<Shift><Super>v" ];
          window-toggle-float = [ "<Super>v" ];
          workspace-active-tile-toggle = [ "<Shift><Super>w" ];
        };
        "org/gnome/shell/extensions/just-perfection" = {
          notification-banner-position = 1;
          panel-button-padding-size = 0;
          panel-indicator-padding-size = 0;
          startup-status = 0;
        };
        "org/gnome/shell/extensions/lockkeys" = {
          style = "show-hide-capslock";
        };
        "org/gnome/shell/extensions/nightthemeswitcher/commands" = {
          enabled = true;
          sunrise = "${day_cw}/bin/day_cw.sh";
          sunset = "${night_cw}/bin/night_cw.sh";
        };
        "org/gnome/shell/extensions/nightthemeswitcher/time" = {
          manual-schedule = false;
          nightthemeswitcher-ondemand-keybinding = [ "<Shift><Super>t" ];
          sunrise = 7;
          sunset = 17;
        };
        "org/gnome/shell/extensions/vitals" = {
          alphabetize = false;
          battery-slot = 0;
          fixed-widths = false;
          hide-icons = false;
          hide-zeros = false;
          hot-sensors = [ "_processor_usage_" "_memory_usage_" "__network-rx_max__" ];
          menu-centered = true;
          position-in-panel = 2;
          use-higher-precision = false;
        };
        "org/gnome/shell/extensions/weatherornot" = {
          position = "clock-left";
        };
        "org/gnome/shell/keybindings" = {
          focus-active-notification = [];
          shift-overview-down = [ "<Super><Alt>Down" ];
          shift-overview-up = [ "<Super><Alt>Up" ];
          switch-to-application-1 = [];
          switch-to-application-2 = [];
          switch-to-application-3 = [];
          switch-to-application-4 = [];
          toggle-message-tray = [];
        };
        "org/gnome/shell/weather" = {
          automatic-location = true;
        };
        "org/gnome/system/location" = {
          enabled = true;
        };
        "org/gnome/TextEditor" = {
          restore-session = false;
        };
        "org/gtk/gtk4/settings/file-chooser" = {
          show-hidden = true;
        };
      };

      home.packages = with pkgs.gnomeExtensions; [
        # These 3 are already installed with ExtManager
        #launch-new-instance
        #removable-drive-menu
        #user-themes
        alphabetical-app-grid
        appindicator
        bluetooth-quick-connect
        blur-my-shell
        clipboard-indicator
        forge
        just-perfection
        lock-keys
        night-theme-switcher
        pip-on-top
        power-profile-switcher
        vitals
        weather-or-not
      ];

      # Generate an empty filo from right click menu
      home.file."Templates/Empty file".text = "";

      # Hide neovim from app grid
      xdg.desktopEntries.nvim = {
        name = "Neovim wrapper";
        noDisplay = true;
      };

      # Set default applications
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "image/gif" = [ "org.gnome.Loupe.desktop" ];
          "image/jpg" = [ "org.gnome.Loupe.desktop" ];
          "image/png" = [ "org.gnome.Loupe.desktop" ];
          "text/plain" = [ "neovide.desktop" ];
        };
      };
    };
  };
}
