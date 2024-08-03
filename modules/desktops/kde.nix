{ config, host, lib, pkgs, vars, ... }: with lib; let
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
    sddm = "${vars.configPath}/assets/wallpapers/blobs-l.png";
  };
in {
  options.kde.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.kde.enable) {
    environment = {
      systemPackages = with pkgs; [
        cursor.package                  # For GDM login screen
        icon.package                    # Icon theme
        libsecret                   # Secret storage used by gnome-keyring / KDE-wallet
        neovide                         # GUI launcher for neovim
      ];
      plasma6.excludePackages = with pkgs.kdePackages; [
        #app
      ];
    };

    services = {
      desktopManager.plasma6.enable = true;
      displayManager.sddm = {
        enable = true;
        extraPackages = with pkgs; [
          #elegant-sddm
        ];
        #package = pkgs.kdePackages.sddm;
        #theme = "elegant-sddm";
        wayland = {
          enable = true;
          # Default is weston - kwin or weston
          #compositor = "kwin";
        };
      };

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
        excludePackages = with pkgs; [
          xterm
        ];
      };
    };

    home-manager.users.${vars.user} = { config, lib, ... }: {
      # Sets profile image
      home.file = {
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
        # Set terminal themes
        #alacritty.settings.import = [ "/home/${vars.user}/.config/alacritty/current-theme.toml" ];
        #kitty.extraConfig = ''include /home/${vars.user}/.config/kitty/current-theme.conf'';

        plasma = {
          enable = true;
          # If true, reset all KDE settings not defined in this module
          #overrideConfig = true;

          configFile = {
            # Disable file indexing
            "baloofilerc"."Basic Settings"."Indexing-Enabled" = false;
            # Do not remember file history
            "kactivitymanagerdrc"."Plugins"."org.kde.ActivityManager.ResourceScoringEnabled" = false;
            # Disable file search from KRunner
            "krunnerrc"."Plugins"."baloosearchEnabled" = false;
            "kscreenlockerrc" = {
              # Screen locking timeout
              "Daemon"."Timeout" = 10;
              "Greeter"."WallpaperPlugin" = "org.kde.potd";
              "Greeter/Wallpaper/org.kde.potd/General"."Provider" = "flickr";
            };
            # Start an empty session upon login
            "ksmserverrc"."General"."loginMode" = "emptySession";
            "kwinrc" = {
              # Virtual desktops
              "Desktops" = {
                "Number" = 4;
                "Rows" = 1;
              };
              # Focus follows mouse instead of clicking
              "Windows"."FocusPolicy" = "FocusFollowsMouse";
              "Xwayland"."Scale" = host.resScale;
            };
            # 24 hour time
            #"plasma-localerc"."Formats"."LC_TIME" = "en_GB.UTF-8";
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
                        useAsIcon = false;
                        radius = 8;
                      };
                      icon = "view-media-track";
                    };
                    preferredSource = "any";
                    musicControls = {
                      showPlaybackControls = true;
                      volumeStep = 5;
                    };
                    songText = {
                      displayInSeparateLines = true;
                      maximumWidth = 150;
                      scrolling = {
                        enable = true;
                        behavior = "scrollOnHover";
                        speed = 3;
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
                    showTitle = false;
                    displayStyle = "org.kde.ksysguard.textonly";
                    sensors = [
                      {
                        label = "C";
                        name =  "cpu/all/averageTemperature";
                        color = "170,0,255";
                      }
                    ];
                  };
                }
                {
                  systemMonitor = {
                    title = "GPU Temperature";
                    showTitle = false;
                    displayStyle = "org.kde.ksysguard.textonly";
                    sensors = [
                      {
                        label = "G";
                        name = "gpu/gpu0/temperature";
                        color = "0,200,0";
                      }
                    ];
                  };
                }
                "org.kde.plasma.marginsseparator"
                {
                  systemTray = {
                    items = {
                      # We explicitly show bluetooth and battery
                      shown = [
                        "org.kde.plasma.bluetooth"
                        "org.kde.plasma.volume"
                        "org.kde.plasma.networkmanagement"
                        "org.kde.plasma.battery"
                      ];
                      # And explicitly hide networkmanagement and volume
                      hidden = [
                        "org.kde.plasma.brightness"
                        "org.kde.plasma.clipboard"
                      ];
                    };
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
                  iconTasks = {
                    launchers = [
                      #"applications:kitty.desktop"
                      #"applications:Alacritty.desktop"
                      "applications:${vars.terminal}.desktop"
                      "applications:org.kde.konsole.desktop"
                      "applications:org.kde.dolphin.desktop"
                      "applications:firefox.desktop"
                      "applications:spotify.desktop"
                      "applications:thunderbird.desktop"
                      "applications:discord.desktop"
                      "applications:steam.desktop"
                      "applications:plexmediaplayer.desktop"
                    ];
                  };
                }
              ];
            }
          ];
          shortcuts = {
            "kwin" = {
              "Switch to Desktop 1" = "Meta+1,,Switch to Desktop 1";
              "Switch to Desktop 2" = "Meta+2,,Switch to Desktop 2";
              "Switch to Desktop 3" = "Meta+3,,Switch to Desktop 3";
              "Switch to Desktop 4" = "Meta+4,,Switch to Desktop 4";
              "Window to Desktop 1" = "Meta+!,,Window to Desktop 1";
              "Window to Desktop 2" = "Meta+@,,Window to Desktop 2";
              "Window to Desktop 3" = "Meta+#,,Window to Desktop 3";
              "Window to Desktop 4" = "Meta+$,,Window to Desktop 4";
              "Window Close" = [ "Alt+F4" "Meta+Q,Alt+F4,Close Window" ];
            };
            "services/firefox.desktop"."_launch" = "Meta+W";
            "services/kitty.desktop"."_launch" = "Meta+Return";
          };

          workspace = {
            cursor = {
              theme = cursor.name;
              size = cursor.size;
            };
            iconTheme = icon.name;
            #wallpaper = wallpaper.day;
          };
        };
      };

      # Hide neovim from app grid
      xdg.desktopEntries.nvim = {
        name = "Neovim wrapper";
        noDisplay = true;
      };

      # Set default applications
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          #"image/gif" = [ "org.gnome.Loupe.desktop" ];
          #"image/jpg" = [ "org.gnome.Loupe.desktop" ];
          #"image/png" = [ "org.gnome.Loupe.desktop" ];
          #"text/plain" = [ "neovide.desktop" ];
        };
      };
    };

  };
}
