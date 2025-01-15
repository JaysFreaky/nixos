{ config, inputs, lib, pkgs, vars, ... }: let
  cfg = config.myOptions.desktops.kde;
  cfg-base = config.myOptions;
  host = config.myHosts;

  alacritty = {
    dark = "catppuccin_mocha";
    light = "catppuccin_latte";
  };
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
  profileImg = ../../assets/profile.png;
  wallpaper = {
    dark = "${vars.configPath}/assets/wallpapers/dark.png";
    light = "${vars.configPath}/assets/wallpapers/light.png";
    sddm = "${vars.configPath}/assets/wallpapers/login.png";
  };
in {
  options.myOptions.desktops.kde = with lib; {
    enable = mkEnableOption "KDE desktop";
    cpuWidget = mkOption {
      default = "cpu/all/averageTemperature";
      description = "The nested path of the widget's sensor details. Paths can be found at '.config/plasma-org.kde.plasma.desktop-appletsrc'";
      example = "cpu/all/averageTemperature";
      type = types.nullOr types.str;
    };
    gpuWidget = mkOption {
      default = null;
      description = "The nested path of the widget's sensor details. Paths can be found at '.config/plasma-org.kde.plasma.desktop-appletsrc'";
      example = "gpu/gpu0/temperature";
      type = types.nullOr types.str;
    };
    gpuWidget2 = mkOption {
      default = null;
      description = "The nested path of the widget's sensor details. Paths can be found at '.config/plasma-org.kde.plasma.desktop-appletsrc'";
      example = "gpu/gpu1/temperature";
      type = types.nullOr types.str;
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment = {
      systemPackages = with pkgs; let
        sddm-astronaut-pkg = pkgs.sddm-astronaut.override {
          themeConfig = {
          # Screen
            ScreenWidth = "${host.width}";
            ScreenHeight = "${host.height}";
          # Background
            Background = "${wallpaper.sddm}";
          # Form
            FormPosition = "left";  # left, center, right
            PartialBlur = false;    # Form is blurred
            FullBlur = true;        # Everything is blurred
            Blur = 1.0;             # Default 2.0 | 0.0 - 3.0
            BlurMax = 64;           # Default 48 | 2 - 64
          # UI
            ForceHideVirtualKeyboardButton = true;
          };
        };
      in [
      # Theming
        cursor.package              # For SDDM login screen
        icon.package                # Icon theme
        sddm-astronaut-pkg          # SDDM theme

      # Misc
        libsecret                   # Secret storage used by gnome-keyring / KDE-wallet

      # Multimedia
        haruna            # MPV frontend
        mpc-qt            # MPV frontend

      # Text
        neovide                     # GUI launcher for neovim

      # Window Management
        #polonium                    # Window tiling
      ] ++ (with kdePackages; [
        dragon                      # Media player
        #kwallet                     # KDE Wallet
        #kwallet-pam                 # Unlock on login
        #kwalletmanager              # Wallet manager
        qt5compat                   # Qt5 compatibility
        sddm-kcm                    # SDDM settings module
      ]);
      plasma6.excludePackages = with pkgs.kdePackages; [ ];
    };

    #security.pam.services.sddm.kwallet.enable = true;

    services = {
      desktopManager.plasma6.enable = true;
      displayManager.sddm = {
        enable = true;
        extraPackages = [ pkgs.kdePackages.qt5compat ];
        settings = {
          Theme = {
            CursorSize = cursor.size;
            CursorTheme = cursor.name;
          };
        };
        theme = "sddm-astronaut-theme";
        wayland.enable = true;
      };

      xserver = {
        enable = true;
        excludePackages = with pkgs; [ xterm ];
      };
    };

    # Workaround to display profile image at login screen - image needs +x
    system.activationScripts.showProfileImage.text = ''
      mkdir -p /var/lib/AccountsService/{icons,users}
      cp /home/${vars.user}/.face /var/lib/AccountsService/icons/${vars.user}

      echo -e "[User]\nIcon=/var/lib/AccountsService/icons/${vars.user}\n" > /var/lib/AccountsService/users/${vars.user}
    '';

    home-manager.users.${vars.user} = {
      imports = [ inputs.plasma-manager.homeManagerModules.plasma-manager ];

      home.file = {
        # Sets profile image
        ".face".source = profileImg;
        # KRunner web search providers
        ".local/share/kf6/searchproviders/hm.desktop".text = ''
          [Desktop Entry]
          Charset=
          Hidden=false
          Keys=hm
          Name=Home Manager
          Query=https://home-manager-options.extranix.com/?query=\\{@}&release=master
          Type=Service
        '';
        ".local/share/kf6/searchproviders/no.desktop".text = ''
          [Desktop Entry]
          Charset=
          Hidden=false
          Keys=no
          Name=Nix Options
          Query=https://search.nixos.org/options?channel=unstable&query=\\{@}
          Type=Service
        '';
        ".local/share/kf6/searchproviders/np.desktop".text = ''
          [Desktop Entry]
          Charset=
          Hidden=false
          Keys=np
          Name=Nix Packages
          Query=https://search.nixos.org/packages?channel=unstable&query=\\{@}
          Type=Service
        '';
        ".local/share/kf6/searchproviders/nw.desktop".text = ''
          [Desktop Entry]
          Charset=
          Hidden=false
          Keys=nw
          Name=NixOS Wiki
          Query=https://wiki.nixos.org/wiki/\\{@}
          Type=Service
        '';
        ".local/share/kf6/searchproviders/sp.desktop".text = ''
          [Desktop Entry]
          Charset=
          Hidden=false
          Keys=sp
          Name=Startpage
          Query=https://www.startpage.com/sp/search?query=\\{@}
          Type=Service
        '';
      };

      programs = {
        plasma = {
          enable = true;
          # If true, resets all KDE settings not defined in this module @ boot/login
          #overrideConfig = true;

          configFile = {
            # Disable file indexing
            "baloofilerc"."Basic Settings"."Indexing-Enabled" = false;
            "dolphinrc"."General" = {
              "HomeUrl" = "/home/${vars.user}";
              "RememberOpenedTabs" = false;
            };
            # Do not remember file history
            "kactivitymanagerdrc"."Plugins"."org.kde.ActivityManager.ResourceScoringEnabled" = false;
            # Cursor size & theme
            "kcminputrc"."Mouse" = {
              "cursorSize" = cursor.size;
              "cursorTheme" = cursor.name;
            };
            "kdeglobals" = {
              # Icon theme
              "Icons"."Theme" = icon.name;
              # Dolphin thumbnails
              "PreviewSettings" = {
                "EnableRemoteFolderThumbnail" = true;
                # 20 MiB
                "MaximumRemoteSize" = 20971520;
              };
            };
            "krunnerrc" = {
              # Center krunner on screen
              "General"."FreeFloating" = true;
              # Disable search history
              "General"."historyBehavior" = "Disabled";
              # Disable file search from KRunner
              "Plugins"."baloosearchEnabled" = false;
            };
            "kscreenlockerrc" = {
              # Screen locking timeout & plugin / provider
              "Daemon"."Timeout" = 10;
              "Greeter"."WallpaperPlugin" = "org.kde.potd";
              # Astronomy (NASA) is set by commenting out the provider
                # Providers: bing, natgeo, noaa, wcpotd
              #"Greeter/Wallpaper/org.kde.potd/General"."Provider" = "natgeo";
            };
            # Start an empty session upon login
            "ksmserverrc"."General"."loginMode" = "emptySession";
            "kwinrc" = {
              # Virtual desktops
              "Desktops" = {
                "Number" = 4;
                "Rows" = 1;
              };
              # Screen edge - Top-center
              "Effect-overview"."BorderActivate" = 0;
              # Screen edge - Top-left
              "ElectricBorders"."TopLeft" = "ApplicationLauncher";
              # Screen edge - Top-right
              "ElectricBorders"."TopRight" = "ShowDesktop";
              "Windows" = {
                # Screen edge reactivation delay in ms
                "ElectricBorderCooldown" = 225;
                # Screen edge delay in ms
                "ElectricBorderDelay" = 175;
                # Focus follows mouse instead of clicking
                "FocusPolicy" = "FocusFollowsMouse";
              };
              # Set host scaling
              "Xwayland"."Scale" = host.scale;
            };
          };

          panels = [
            # Top panel
            {
              alignment = "center";
              floating = true;
              height = 44;
              hiding = "normalpanel";
              lengthMode = "fill";
              location = "top";
              widgets = [
                {
                  kickoff = {
                    sortAlphabetically = true;
                    icon = "nix-snowflake";
                  };
                }
                "org.kde.plasma.pager"
                "org.kde.plasma.marginsseparator"
                {
                  plasmusicToolbar = {
                    panelIcon = {
                      albumCover = {
                        fallbackToIcon = true;
                        radius = 10;
                        useAsIcon = true;
                      };
                      icon = "view-media-track";
                    };
                    playbackSource = "auto";
                    musicControls = {
                      showPlaybackControls = true;
                      volumeStep = 5;
                    };
                    songText = {
                      displayInSeparateLines = true;
                      maximumWidth = 150;
                      scrolling = {
                        enable = true;
                        behavior = "alwaysScrollExceptOnHover";
                        resetOnPause = true;
                        speed = 1;
                      };
                    };
                  };
                }
                "org.kde.plasma.panelspacer"
                {
                  digitalClock = {
                    calendar.firstDayOfWeek = "sunday";
                    time.format = "24h";
                  };
                }
                "org.kde.plasma.panelspacer"
                {
                  systemMonitor = {
                    title = "CPU Temperature";
                    showTitle = true;
                    displayStyle = "org.kde.ksysguard.textonly";
                    sensors = [
                      {
                        label = "CPU";
                        name = "${cfg.cpuWidget}";
                        color = "125,60,235";
                      }
                    ];
                  };
                }
              ] ++ lib.optionals (cfg.gpuWidget != null) [
                {
                  systemMonitor = {
                    title = "GPU Temperature";
                    showTitle = true;
                    displayStyle = "org.kde.ksysguard.textonly";
                    sensors = [
                      {
                        label = "GPU";
                        name = "${cfg.gpuWidget}";
                        color = "0,200,0";
                      }
                    ] ++ lib.optionals (cfg.gpuWidget2 != null) [
                      {
                        label = "GPU 2";
                        name = "${cfg.gpuWidget2}";
                        color = "0,125,255";
                      }
                    ];
                  };
                }
              ] ++ [
                "org.kde.plasma.marginsseparator"
                {
                  systemTray.items = {
                    hidden = [
                      "org.kde.plasma.brightness"
                      "org.kde.plasma.clipboard"
                      "org.kde.plasma.mediacontroller"
                    ] ++ lib.optionals (config.hardware.bluetooth.enable) [
                      "org.kde.plasma.bluetooth"
                    ];
                    shown = [
                      "chrome_status_icon_1"              # 1Password
                      "org.kde.plasma.volume"
                    ] ++ lib.optionals (config.hardware.bluetooth.enable) [
                      "blueman"
                    ] ++ [
                      "org.kde.plasma.networkmanagement"
                      "org.kde.plasma.battery"
                    ];
                  };
                }
              ];
            }

            # Bottom Panel
            {
              alignment = "center";
              floating = true;
              height = 50;
              hiding = "autohide";
              lengthMode = "fit";
              location = "bottom";
              widgets = [
                {
                  iconTasks.launchers = [
                    "applications:${vars.terminal}.desktop"
                    "applications:org.kde.dolphin.desktop"
                    "applications:${cfg-base.browser}.desktop"
                    "applications:spotify.desktop"
                    #"applications:thunderbird.desktop"
                    "applications:discord.desktop"
                    "applications:steam.desktop"
                    "applications:${cfg-base.plex.shortcut}"
                  ];
                }
              ];
            }
          ];

          shortcuts = {
            "kwin" = {
              "Overview" = "Meta+Tab";
              "Switch to Desktop 1" = "Meta+1";
              "Switch to Desktop 2" = "Meta+2";
              "Switch to Desktop 3" = "Meta+3";
              "Switch to Desktop 4" = "Meta+4";
              "Switch to Desktop 5" = "Meta+5";
              "Switch to Desktop 6" = "Meta+6";
              "Switch to Desktop 7" = "Meta+7";
              "Switch to Desktop 8" = "Meta+8";
              "Switch to Desktop 9" = "Meta+9";
              "Switch to Desktop 10" = "Meta+0";
              "Window Close" = [ "Meta+Q" "Alt+F4" ];
              "Window Maximize" = "Meta+Up";
              "Window Minimize" = "Meta+Down";
              "Window Quick Tile Bottom" = "";
              "Window Quick Tile Top" = "";
              "Window to Desktop 1" = "Meta+!";
              "Window to Desktop 2" = "Meta+@";
              "Window to Desktop 3" = "Meta+#";
              "Window to Desktop 4" = "Meta+$";
              "Window to Desktop 5" = "Meta+%";
              "Window to Desktop 6" = "Meta+^";
              "Window to Desktop 7" = "Meta+&";
              "Window to Desktop 8" = "Meta+*";
              "Window to Desktop 9" = "Meta+(";
              "Window to Desktop 10" = "Meta+)";
            };
            "plasmashell" = {
              "activate task manager entry 1" = [ ];
              "activate task manager entry 2" = [ ];
              "activate task manager entry 3" = [ ];
              "activate task manager entry 4" = [ ];
              "activate task manager entry 5" = [ ];
              "activate task manager entry 6" = [ ];
              "activate task manager entry 7" = [ ];
              "activate task manager entry 8" = [ ];
              "activate task manager entry 9" = [ ];
              "activate task manager entry 10" = [ ];
              "manage activities" = [ ];
            };
            "services/${cfg-base.browser}.desktop"."_launch" = "Meta+W";
            "services/${vars.terminal}.desktop"."_launch" = "Meta+Return";
            "services/darkman.desktop"."_launch" = "Meta+Shift+T";
            "services/org.kde.krunner.desktop"."_launch" = [ "" "Alt+Space" "Meta+Space" "Search" "Alt+F2" ];
          };

          # Setting cursor/icon themes via configFile
          #workspace.cursor.theme = cursor.name;
          #workspace.cursor.size = cursor.size;
          #workspace.iconTheme = icon.name;
          #workspace.wallpaper = wallpaper.light;
        };
      };

      services.darkman = let
        lookandfeeltool = lib.getExe' pkgs.kdePackages.plasma-workspace "lookandfeeltool";
        qdbus = lib.getExe' pkgs.kdePackages.qttools "qdbus";
      in {
        enable = true;
        darkModeScripts = {
          alacritty = lib.mkIf (cfg-base.alacritty.enable) ''ln -fs ${pkgs.alacritty-theme}/${alacritty.dark}.toml /home/${vars.user}/.config/alacritty/current-theme.toml'';
          kitty = lib.mkIf (cfg-base.kitty.enable) ''
            ln -fs ${pkgs.kitty-themes}/share/kitty-themes/themes/${kitty.dark}.conf /home/${vars.user}/.config/kitty/current-theme.conf
            kill -SIGUSR1 $(pidof kitty) 2>/dev/null
          '';
          plasma_global_theme = ''${lookandfeeltool} --apply "org.kde.breezedark.desktop"'';
          wallpaper = ''
            ${qdbus} org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'var allDesktops = desktops();print (allDesktops);for (i=0;i<allDesktops.length;i++) {d = allDesktops[i];d.wallpaperPlugin = "org.kde.image";d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General");d.writeConfig("Image", "file://'${wallpaper.dark}'")}'
          '';
        };

        lightModeScripts = {
          alacritty = lib.mkIf (cfg-base.alacritty.enable) ''ln -fs ${pkgs.alacritty-theme}/${alacritty.light}.toml /home/${vars.user}/.config/alacritty/current-theme.toml'';
          kitty = lib.mkIf (cfg-base.kitty.enable) ''
            ln -fs ${pkgs.kitty-themes}/share/kitty-themes/themes/${kitty.light}.conf /home/${vars.user}/.config/kitty/current-theme.conf
            kill -SIGUSR1 $(pidof kitty) 2>/dev/null
          '';
          plasma_global_theme = ''${lookandfeeltool} --apply "org.kde.breeze.desktop"'';
          wallpaper = ''
            ${qdbus} org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'var allDesktops = desktops();print (allDesktops);for (i=0;i<allDesktops.length;i++) {d = allDesktops[i];d.wallpaperPlugin = "org.kde.image";d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General");d.writeConfig("Image", "file://'${wallpaper.light}'")}'
          '';
        };
      };

      # Set default application file associations
      mimeApps = let
        mime = {
          archive = [ "org.kde.ark.desktop" ];
          audio = [ "org.kde.elisa.desktop" ];
          calendar = [ "" ];
          image = [ "org.kde.gwenview.desktop" ];
          pdf = [ "okularApplication_pdf.desktop" ];
          text = [ "org.kde.kate.desktop" ];
          video = [
            "mpc-qt.desktop"
            #"org.kde.haruna.desktop"
            #"org.kde.dragonplayer.desktop"
          ];
        };
      in {
        enable = true;
        associations.added = config.xdg.mimeApps.defaultApplications;
        defaultApplications = import ./mimeapps.nix { inherit mime; };
      };
    };

  };
}
