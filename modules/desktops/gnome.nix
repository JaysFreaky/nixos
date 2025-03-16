{
  config,
  lib,
  pkgs,
  #cfgHosts,
  cfgOpts,
  cfgTerm,
  inputs,
  myUser,
  ...
}: let
  cfg = cfgOpts.desktops.gnome;
  stylix = config.stylix.enable;

  kitty = {
    dark = "Catppuccin-Mocha";
    light = "Catppuccin-Latte";
  };
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
  logoImg = ../../assets/logo.png;
  profileImg = ../../assets/profile.png;
  switch-mode = pkgs.callPackage ../programs/stylix/switch-mode.nix { };
  themeChange = pkgs.writeShellScriptBin "themeChange" ''
    CURRENT_THEME=$(gsettings get org.gnome.desktop.interface color-scheme | cut -d "'" -f 2)
    if [[ "$CURRENT_THEME" = "default" ]]; then
      # Kitty
      ln -fs ${pkgs.kitty-themes}/share/kitty-themes/themes/${kitty.light}.conf /home/${myUser}/.config/kitty/current-theme.conf
      kill -SIGUSR1 $(pidof kitty) 2>/dev/null
      # Wallpaper
      gsettings set org.gnome.desktop.background picture-uri '${inputs.nixos-artwork}/wallpapers/nix-wallpaper-binary-blue.png'
    elif [[ "$CURRENT_THEME" = "prefer-dark" ]]; then
      # Kitty
      ln -fs ${pkgs.kitty-themes}/share/kitty-themes/themes/${kitty.dark}.conf /home/${myUser}/.config/kitty/current-theme.conf
      kill -SIGUSR1 $(pidof kitty) 2>/dev/null
      # Wallpaper
      gsettings set org.gnome.desktop.background picture-uri-dark '${inputs.nixos-artwork}/wallpapers/nix-wallpaper-binary-black.png'
    fi;
  '';
in {
  options.myOptions.desktops.gnome.enable = lib.mkEnableOption "GNOME desktop";

  config = lib.mkIf (cfg.enable) {
    environment = {
      gnome.excludePackages = builtins.attrValues {
        inherit (pkgs)
          cheese                      # "fun" webcam app
          epiphany                    # Web browser
          #evince                     # Document viewer
          geary                       # Email client
          #gedit                      # Text editor
          gnome-characters            # Character map
          gnome-contacts              # Contact app
          gnome-initial-setup         # First time setup
          #gnome-music                # Music
          #gnome-maps                 # Maps
          #gnome-photos               # Image viewer
          #gnome-terminal             # Console
          gnome-tour                  # Setup walkthrough
          #loupe                      # Image viewer
          simple-scan                 # Scanning app
          #snapshot                   # Webcam
          totem                       # Video player
          yelp                        # Help
        ;
      };

      systemPackages = [
      # Theming
        cursor.package                # GDM login screen
      ] ++ builtins.attrValues {
        inherit (pkgs)
        # GNOME
          dconf-editor                # GUI dconf editor
          gnome-extension-manager     # Gnome extensions
          gnome-tweaks                # Gnome tweaks
          libappindicator             # Allow tray icons to be displayed in GNOME
          nautilus-open-any-terminal  # Open custom terminals in nautilus
          nautilus-python             # Allow custom nautilus scripts/open-any-terminal

        # Multimedia
          celluloid                   # MPV GTK frontend w/ Wayland
          clapper                     # GTK media player

        # Text
          neovide                     # GUI launcher for neovim
        ;
      };
      # Fix black borders around windows until amdvlk patch
      variables.GSK_RENDERER = "gl";
    };

    nixpkgs.overlays = lib.mkIf (cfgOpts.git.ssh.enable && cfgOpts."1password".enable) [
      (final: prev: {
        gnome-keyring = prev.gnome-keyring.overrideAttrs (oldAttrs: {
          configureFlags = (builtins.filter (flag: flag != "--enable-ssh-agent") oldAttrs.configureFlags) ++ [ "--disable-ssh-agent" ];
        });
      })
    ];

    programs = {
      kdeconnect = {
        enable = true;
        package = pkgs.gnomeExtensions.gsconnect;
      };

      # GUI manager for keys/passwords in gnome-keyring
      seahorse.enable = true;

      # GDM login screen settings
      dconf.profiles.gdm.databases = [{
        settings = {
          "org/gnome/desktop/interface" = {
            cursor-size = lib.gvariant.mkInt32 24;
            cursor-theme = "Bibata-Modern-Classic";
          };
          "org/gnome/desktop/peripherals/touchpad" = {
            tap-to-click = true;
          };
          "org/gnome/login-screen".logo = builtins.toString logoImg;
          "org/gnome/mutter".experimental-features = [
            "scale-monitor-framebuffer"
            "xwayland-native-scaling"
          ];
        };
      }];
    };

    # Unlock keyring upon login
    security.pam.services.gdm.enableGnomeKeyring = true;

    services = {
      gnome = {
        gnome-browser-connector.enable = true;
        gnome-keyring.enable = true;
        sushi.enable = true;
      };

      xserver = {
        enable = true;
        desktopManager.gnome.enable = true;
        displayManager.gdm.enable = true;
        excludePackages = [ pkgs.xterm ];
      };

      # Enable additional systray icons
      udev.packages = [ pkgs.gnome-settings-daemon ];
    };

    # Workaround to display profile image at login screen - image needs +x
    system.activationScripts.showProfileImage.text = ''
      mkdir -p /var/lib/AccountsService/{icons,users}
      cp /home/${myUser}/.face /var/lib/AccountsService/icons/${myUser}
      echo -e "[User]\nIcon=/var/lib/AccountsService/icons/${myUser}\nSession=gnome\nSystemAccount=false\n" > /var/lib/AccountsService/users/${myUser}
    '';
 
    home-manager.users.${myUser} = { config, lib, ... }: let
      gnomeExts = builtins.attrValues {
        inherit (pkgs.gnomeExtensions)
          alphabetical-app-grid
          appindicator
          bluetooth-quick-connect
          blur-my-shell
          clipboard-indicator
          hibernate-status-button
          hot-edge
          just-perfection
          lock-keys
          night-theme-switcher
          notification-timeout
          power-profile-switcher
          vitals
          weather-or-not
        ;
      };
    in {
      dconf.settings = {
        "ca/desrt/dconf-editor".show-warning = false;
        "com/github/stunkymonkey/nautilus-open-any-terminal" = {
          new-tab = true;
          terminal = cfgTerm;
        };
        "org/gnome/Console" = {
          custom-font = "JetBrainsMonoNL Nerd Font Mono 13";
          ignore-scrollback-limit = true;
          use-system-font = false;
        };
        "org/gnome/desktop/datetime".automatic-timezone = true;
        "org/gnome/desktop/interface" = {
          accent-color = "purple";
          clock-show-date = true;
          clock-show-weekday = true;
          #color-scheme = "prefer-dark";
          font-antialiasing = "rgba";
          show-battery-percentage = true;
          #text-scaling-factor = cfgHosts.scale;
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
        "org/gnome/desktop/session".idle-delay = lib.hm.gvariant.mkUint32 300;
        "org/gnome/desktop/wm/keybindings" = {
          close = [ "<Super>q" ];
          #maximize = [];
          #minimize = [];
          move-to-monitor-down = [];
          move-to-monitor-left = [];
          move-to-monitor-right = [];
          move-to-monitor-up = [];
          move-to-workspace-1 = [ "<Shift><Super>1" ];
          move-to-workspace-2 = [ "<Shift><Super>2" ];
          move-to-workspace-3 = [ "<Shift><Super>3" ];
          move-to-workspace-4 = [ "<Shift><Super>4" ];
          move-to-workspace-5 = [ "<Shift><Super>5" ];
          move-to-workspace-6 = [ "<Shift><Super>6" ];
          move-to-workspace-7 = [ "<Shift><Super>7" ];
          move-to-workspace-8 = [ "<Shift><Super>8" ];
          move-to-workspace-9 = [ "<Shift><Super>9" ];
          move-to-workspace-10 = [ "<Shift><Super>0" ];
          switch-applications = [
            "<Super>Tab"
            "<Alt>Tab"
          ];
          switch-applications-backward = [
            "<Shift><Super>Tab"
            "<Shift><Alt>Tab"
          ];
          switch-group = [
            "<Super>Above_Tab"
            "<Alt>Above_Tab"
          ];
          switch-group-backward = [
            "<Shift><Super>Above_Tab"
            "<Shift><Alt>Above_Tab"
          ];
          switch-input-source = [];
          switch-input-source-backward = [];
          switch-to-workspace-1 = [ "<Super>1" ];
          switch-to-workspace-2 = [ "<Super>2" ];
          switch-to-workspace-3 = [ "<Super>3" ];
          switch-to-workspace-4 = [ "<Super>4" ];
          switch-to-workspace-5 = [ "<Super>5" ];
          switch-to-workspace-6 = [ "<Super>6" ];
          switch-to-workspace-7 = [ "<Super>7" ];
          switch-to-workspace-8 = [ "<Super>8" ];
          switch-to-workspace-9 = [ "<Super>9" ];
          switch-to-workspace-10 = [ "<Super>0" ];
          switch-to-workspace-last = [ "<Super>End" ];
          switch-to-workspace-left = [
            "<Super>Page_Up"
            "<Super><Alt>Left"
            "<Control><Alt>Left"
          ];
          switch-to-workspace-right = [
            "<Super>Page_Down"
            "<Super><Alt>Right"
            "<Control><Alt>Right"
          ];
          toggle-fullscreen = [ "<Super>f" ];
          #unmaximize = [];
        };
        "org/gnome/desktop/wm/preferences" = {
          button-layout = "appmenu:minimize,maximize,close";
          focus-mode = "sloppy";
          mouse-button-modifier = "<Alt>";
          #num-workspaces = 4;
          workspace-names = [];
        };
        "org/gnome/mutter" = {
          center-new-windows = true;
          dynamic-workspaces = true;
          edge-tiling = true;
          # Adds scaling/vrr options under Settings->Display
          experimental-features = [
            "scale-monitor-framebuffer"
            "variable-refresh-rate"
          ];
          workspaces-only-on-primary = false;
        };
        "org/gnome/mutter/keybindings" = {
          #cancel-input-capture = [ "<Super><Shift>Escape" ];
          #toggle-tiled-left = [];
          #toggle-tiled-right = [];
        };
        "org/gnome/mutter/wayland/keybindings".restore-shortcuts = [];
        "org/gnome/nautilus/icon-view".default-zoom-level = "small";
        "org/gnome/nautilus/list-view".default-zoom-level = "small";
        "org/gnome/nautilus/preferences" = {
          always-use-location-entry = false;
          default-folder-viewer = "list-view";  # 'icon-view' or 'list-view'
        };
        "org/gnome/settings-daemon/plugins/media-keys" = {
          custom-keybindings = [ "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/" ];
          help = [];
          home = [ "<Super>e" ];
          magnifier = [];
          magnifier-zoom-in = [];
          magnifier-zoom-out = [];
          rotate-video-lock-static = [
            "<Super>o"
            "XF86RotationLockToggle"
          ];
          screenreader = [];
          screensaver = [ "<Super>l" ];
          www = [ "<Super>w" ];
        };
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          binding = "<Super>Return";
          command = cfgTerm;
          name = "Launch Terminal";
        };
        "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "nothing";
        "org/gnome/shell" = {
          enabled-extensions = (map (extension: extension.extensionUuid) gnomeExts) ++ [
            # Enable extensions that ship, but aren't enabled by default
            "drive-menu@gnome-shell-extensions.gcampax.github.com"
            "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
            "user-theme@gnome-shell-extensions.gcampax.github.com"
          ];
          disable-user-extensions = false;
          favorite-apps = [
            "${cfgTerm}.desktop"
            "org.gnome.Nautilus.desktop"
            "${cfgOpts.browser}.desktop"
            "thunderbird.desktop"
            "discord.desktop"
            "steam.desktop"
            "spotify.desktop"
            "plex-desktop.desktop"
          ];
        };
        "org/gnome/shell/extensions/appindicator".icon-size = 16;
        "org/gnome/shell/extensions/bluetooth-quick-connect" = {
          bluetooth-auto-power-off = true;
          bluetooth-auto-power-off-interval = 180;
          refresh-button-on = true;
          show-battery-icon-on = true;
          show-battery-value-on = true;
        };
        "org/gnome/shell/extensions/blur-my-shell".hacks-level = 3;
        "org/gnome/shell/extensions/blur-my-shell/applications" = {
          blur = true;
          blur-on-overview = true;
          customize = true;
          dynamic-opacity = false;
          opacity = 230; # 90%
          sigma = 8;
          whitelist = [
            "kitty"
            "org.gnome.Console"
          ];
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
        "org/gnome/shell/extensions/dash-to-dock" = {
          apply-custom-theme = true;
          custom-theme-shrink = true;
          disable-overview-on-startup = true;
          hot-keys = false;
          intellihide-mode = "ALL_WINDOWS";
          scroll-action = "switch-workspace";
          show-trash = false;
        };
        "org/gnome/shell/extensions/hibernate-status-button" = {
          show-hybrid-sleep = false;
          show-suspend-then-hibernate = false;
        };
        "org/gnome/shell/extensions/just-perfection" = {
          # 1=top center
          notification-banner-position = 1;
          # 3=2px
          panel-button-padding-size = 3;
          # 0=shell theme
          panel-indicator-padding-size = 0;
          # 0=desktop, 1=overview
          startup-status = 0;
        };
        "org/gnome/shell/extensions/lockkeys".style = "show-hide-capslock";
        "org/gnome/shell/extensions/nightthemeswitcher/commands" = {
          enabled = true;
          sunrise = (
            if (stylix)
              then "${lib.getExe switch-mode} light"
            else "${lib.getExe themeChange}"
          );
          sunset = (
            if (stylix)
              then "${lib.getExe switch-mode} dark"
            else "${lib.getExe themeChange}"
          );
        };
        "org/gnome/shell/extensions/nightthemeswitcher/time" = {
          manual-schedule = false;
          nightthemeswitcher-ondemand-keybinding = [ "<Shift><Super>t" ];
          sunrise = 7;
          sunset = 17;
        };
        "org/gnome/shell/extensions/notification-timeout" = {
          always-normal = true;
          ignore-idle = true;
          timeout = 5000;
        };
        "org/gnome/shell/extensions/vitals" = {
          alphabetize = false;
          fixed-widths = false;
          hide-icons = false;
          hide-zeros = false;
          menu-centered = true;
          position-in-panel = 2;
          update-time = 2;  # 5 seconds default
          use-higher-precision = false;
        };
        "org/gnome/shell/extensions/weatherornot".position = "clock-left";
        "org/gnome/shell/keybindings" = {
          focus-active-notification = [];
          shift-overview-down = [ "<Super><Alt>Down" ];
          shift-overview-up = [ "<Super><Alt>Up" ];
          switch-to-application-1 = [];
          switch-to-application-2 = [];
          switch-to-application-3 = [];
          switch-to-application-4 = [];
          switch-to-application-5 = [];
          switch-to-application-6 = [];
          switch-to-application-7 = [];
          switch-to-application-8 = [];
          switch-to-application-9 = [];
          switch-to-application-0 = [];
          toggle-message-tray = [];
        };
        "org/gnome/shell/weather".automatic-location = true;
        "org/gnome/system/location".enabled = true;
        "org/gnome/TextEditor" = {
          restore-session = false;
          show-line-numbers = true;
          tab-width = 2;
        };
        "org/gtk/gtk4/settings/file-chooser".show-hidden = true;
      };

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
      };

      home.file = {
        # Sets profile image
        ".face".source = profileImg;
        # Generate an empty file from right-click menu
        "Templates/Empty file".text = "";
      };

      home.packages = gnomeExts;

      /*
      # https://home-manager-options.extranix.com/?query=neovide&release=master
      programs.neovide = {
        enable = true;
        settings = {
          neovim-bin = (
            if (config.programs.nixvim.enable)
              then "${lib.getExe config.programs.nixvim.package}"
            else "${lib.getExe pkgs.neovim}"
          );
        };
      };
      */

      xdg = {
        # Set Nautilus bookmarks
        configFile."gtk-3.0/bookmarks".text = ''
          file:/// /
          file:///etc/nixos nixos
          file:///mnt/nas nas
        '';

        # Hide neovim icon from app grid
        desktopEntries.nvim = {
          name = "Neovim wrapper";
          noDisplay = true;
        };

        # Set default application file associations
        mimeApps = let
          mime = {
            archive = [ "org.gnome.FileRoller.desktop" ];
            audio = [ "org.gnome.Music.desktop" ];
            browser = [ "${cfgOpts.browser}.desktop" ];
            calendar = [
              "org.gnome.Calendar.desktop"
              #"thunderbird.desktop"
            ];
            #email = [ "thunderbird.desktop" ];
            connect = [ "org.gnome.Shell.Extensions.GSConnect.desktop" ];
            image = [ "org.gnome.Loupe.desktop" ];
            pdf = [ "org.gnome.Evince.desktop" ];
            text = [ "org.gnome.TextEditor.desktop" ];
            video = [ "io.github.celluloid_player.Celluloid.desktop" ];
          };
        in {
          enable = true;
          associations.added = config.xdg.mimeApps.defaultApplications;
          defaultApplications = import ./mimeapps.nix { inherit mime; };
        };
      };
    };
  };
}
