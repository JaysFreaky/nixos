{ config, host, inputs, lib, pkgs, vars, ... }: with lib; let
  #hyprland-pkg = inputs.hyprland.packages.${pkgs.system}; 
  wallpaper = {
    dir = "${vars.configPath}/assets/wallpapers";
    day = "${wallpaper.dir}/blobs-l.png";
    night = "${wallpaper.dir}/blobs-d.png";
    regreet = "${wallpaper.dir}/blobs-l.png";
  };
in {
  imports = [
    #inputs.hyprland.homeManagerModules.default
  ];

  options.hyprland.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.hyprland.enable) {
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

        # Notification
          #mako                     #

        # Screenshot
          grim                      #
          slurp                     #

        # Session Management
          nwg-bar                   #
          wlogout                   #

        # Status bar
          #eww-wayland              #
          #waybar                   #
          #networkmanagerapplet     # Show network tray icon (nm-applet --indicator)

        # Theming
          pywal                     # Theme colors from current wallpaper
          #wpgtk                    # Pywal GUI


        # Wallpaper
          #hyprpapr                 #
          swww                      # Manager capable of GIFs

        # Wayland
          libsForQt5.qt5.qtwayland  # QT5 Wayland support
          #meson                    # Build system - not needed?
          qt6.qtwayland             # QT6 Wayland support
          wayland-protocols         # Wayland protocol extensions
          wayland-utils             # Wayland utilities | 'wayland-info'
          wev                       # Keymapper
          wlroots                   # Wayland compositor library
          xwayland                  # Interface X11 apps with Wayland
      ];
    };

    programs = {
      hyprland = {
        enable = true;
        #package = hyprland-pkg.hyprland;
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

      waybar = {
        enable = true;
        package = pkgs.waybar;
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
          session = "${pkgs.hyprland}/bin/Hyprland";
          tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
        in rec {
          # Auto login
          default_session = initial_session;
          initial_session = {
            # Regreet command
            #command = "${session}";
            # Tuigreet command
            command = "${tuigreet} --asterisks --remember --remember-user-session --time --cmd ${session}";
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
        network-manager-applet.enable = true;
      };

      wayland.windowManager.hyprland = {
        enable = true;
        # Package doesn't need to be declared since done in the system - use null instead?
        #package = hyprland-pkg.hyprland;
        #package = null;
        systemd.variables = [ "--all" ];
        xwayland.enable = true;

        extraConfig = ''
          # You can split this configuration into multiple files
          # Create your files separately and then link them to this file like this:
          # source = ~/.config/hypr/myColors.conf

          #source = /home/${vars.user}/.cache/wal/colors-hyprland.conf


          ################
          ### MONITORS ###
          ################

          # See https://wiki.hyprland.org/Configuring/Monitors/
          # hyprctl monitors all
          #monitor=name, resolution@htz, position, scale
          #monitor=,preferred,auto,auto


          ###################
          ### MY PROGRAMS ###
          ###################

          # See https://wiki.hyprland.org/Configuring/Keywords/

          # Set programs that you use
          $terminal = ${vars.terminal}
          $fileManager = pcmanfm
          $menu = wofi --show drun


          #################
          ### AUTOSTART ###
          #################

          # Autostart necessary processes (like notifications daemons, status bars, etc.)
          # Or execute your favorite apps at launch like this:
          # exec-once = $terminal
          # exec-once = nm-applet &
          # exec-once = waybar & hyprpaper & firefox

          #exec-once = swww init & wal -R & waybar --config ~/.config/waybar/config.jsonc & mako --config ~/.config/mako/config & nm-applet --indicator
          #exec-once = wl-paste --type text --watch cliphist store  # Stores only text data
          #exec-once = wl-paste --type image --watch cliphist store  # Stores only image data
          #exec-once = ~/.config/hypr/scripts/polkit-kde-agent.sh  # Initialize authentication agent
          exec-once = ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
          #exec-once = ~/.config/hypr/scripts/idle.sh  # Screen locking/timeout
          #exec-once = ~/.config/hypr/scripts/themes.sh  # Set cursors, icons, themes
          #exec-once = ~/.config/hypr/scripts/wallpaper.sh  # Set wallpaper


          #############################
          ### ENVIRONMENT VARIABLES ###
          #############################

          # See https://wiki.hyprland.org/Configuring/Environment-variables/

          #env = XCURSOR_SIZE,24
          #env = HYPRCURSOR_SIZE,24


          #####################
          ### LOOK AND FEEL ###
          #####################

          # Refer to https://wiki.hyprland.org/Configuring/Variables/

          # https://wiki.hyprland.org/Configuring/Variables/#general
          general { 
              gaps_in = 5
              gaps_out = 10

              border_size = 2

              # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
              col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
              col.inactive_border = rgba(595959aa)

              # Set to true enable resizing windows by clicking and dragging on borders and gaps
              resize_on_border = true 

              # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
              allow_tearing = false

              layout = dwindle
          }

          # https://wiki.hyprland.org/Configuring/Variables/#decoration
          decoration {
              rounding = 10

              # Change transparency of focused and unfocused windows
              active_opacity = 1.0
              inactive_opacity = 1.0

              drop_shadow = true
              shadow_range = 4
              shadow_render_power = 3
              col.shadow = rgba(1a1a1aee)

              # https://wiki.hyprland.org/Configuring/Variables/#blur
              blur {
                  enabled = true
                  size = 3
                  passes = 1
                  new_optimizations = true
                  vibrancy = 0.1696
              }
          }

          # https://wiki.hyprland.org/Configuring/Variables/#animations
          animations {
              enabled = true

              # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

              bezier = myBezier, 0.05, 0.9, 0.1, 1.05

              animation = windows, 1, 7, myBezier
              animation = windowsOut, 1, 7, default, popin 80%
              animation = border, 1, 10, default
              animation = borderangle, 1, 8, default
              animation = fade, 1, 7, default
              animation = workspaces, 1, 6, default
          }

          # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
          dwindle {
              pseudotile = true # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
              preserve_split = true # You probably want this
          }

          # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
          master {
              new_status = master
          }

          # https://wiki.hyprland.org/Configuring/Variables/#misc
          misc { 
              force_default_wallpaper = -1 # Set to 0 or 1 to disable the anime mascot wallpapers
              disable_hyprland_logo = false # If true disables the random hyprland logo / anime girl background. :(
          }


          #############
          ### INPUT ###
          #############

          # https://wiki.hyprland.org/Configuring/Variables/#input
          input {
              kb_layout = us
              kb_variant =
              kb_model =
              kb_options =
              kb_rules =

              follow_mouse = 1

              sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

              touchpad {
                  disable_while_typing = true
                  natural_scroll = true
                  tap-to-click = true
                  drag_lock = true
                  tap-and-drag = true
              }
          }

          # https://wiki.hyprland.org/Configuring/Variables/#cursor
          cursor {
            no_hardware_cursors = true
          }

          # https://wiki.hyprland.org/Configuring/Variables/#gestures
          gestures {
              workspace_swipe = true
              workspace_swipe_fingers = 3
          }

          # Example per-device config
          # See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
          device {
              #name = epic-mouse-v1
              #sensitivity = -0.5
          }


          ####################
          ### KEYBINDINGSS ###
          ####################

          # See https://wiki.hyprland.org/Configuring/Keywords/
          $mainMod = SUPER # Sets "Windows" key as main modifier

          # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
          # Use 'wev' to determine unknown keys
          #bind = $mainMod, Q, exec, $terminal
          #bind = $mainMod, C, killactive,
          #bind = $mainMod, M, exit,
          #bind = $mainMod, E, exec, $fileManager
          #bind = $mainMod, V, togglefloating,
          #bind = $mainMod, R, exec, $menu
          #bind = $mainMod, P, pseudo, # dwindle
          #bind = $mainMod, J, togglesplit, # dwindle

          bind = $mainMod, TAB, workspace, e+1  # Scroll through workspaces
          bind = $mainMod, Q, killactive,
          bind = $mainMod, W, exec, firefox
          bind = $mainMod, E, exec, $fileManager
          #bind = $mainMod, R, exec, rofi -show drun
          bind = $mainMod, P, pseudo, # dwindle
          bind = $mainMod, D, exec, $menu
          bind = $mainMod, F, fullscreen,
          bind = $mainMod, J, togglesplit, # dwindle
          #bind = $mainMod, L, exec, ~/.config/hypr/scripts/lock_fade.sh
          bind = $mainMod, RETURN, exec, $terminal
          bind = $mainMod, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy
          #bind = $mainMod, V, exec, cliphist list | rofi --dmenu | cliphist decode | wl-copy
          bind = $mainMod, M, exit,
          bind = , PRINT, exec, grim -l 0 - | wl-copy
          bind = $mainMod, PRINT, exec, grim -l 0 -g "$(slurp)" - | wl-copy
          bind = $mainMod SHIFT, F, togglefloating,
          #bind = $mainMod SHIFT, L, exec, nwg-bar -i "96"
          bind = $mainMod ALT, R, exec, pkill -SIGUSR2 waybar

          # Function key binds
          bind = , XF86AudioMute, exec, amixer sset Master toggle
          bind = , XF86AudioLowerVolume, exec, amixer sset Master 5%-
          bind = , XF86AudioRaiseVolume, exec, amixer sset Master 5%+
          #bind = , XF86, exec, amixer sset Capture toggle  # Mic disabled in firmware
          bind = , XF86MonBrightnessDown, exec, brightnessctl s 10%-
          bind = , XF86MonBrightnessUp, exec, brightnessctl s +10%
          #bind = , XF86Display, , # Presentation mode?
          #bind = , XF86WLAN, , # Disables wifi by default
          #bind = , XF86Tools, , # Settings shortcut?
          #bind = , XF86Search, , # rofi search?
          #bind = , XF86LaunchA, exec, rofi -show drun  # rofi launcher
          #bind = , XF86Explorer, exec, kitty spf

          # Move focus with mainMod + arrow keys
          bind = $mainMod, left, movefocus, l
          bind = $mainMod, right, movefocus, r
          bind = $mainMod, up, movefocus, u
          bind = $mainMod, down, movefocus, d
          
          # Resize windows with mainMod + SHIFT + arrow keys
          bind = $mainMod SHIFT, left, resizeactive, -10 0
          bind = $mainMod SHIFT, right, resizeactive, 10 0
          bind = $mainMod SHIFT, up, resizeactive, 0 -10
          bind = $mainMod SHIFT, down, resizeactive, 0 10

          # Switch workspaces with mainMod + [0-9]
          bind = $mainMod, 1, workspace, 1
          bind = $mainMod, 2, workspace, 2
          bind = $mainMod, 3, workspace, 3
          bind = $mainMod, 4, workspace, 4
          bind = $mainMod, 5, workspace, 5
          bind = $mainMod, 6, workspace, 6
          bind = $mainMod, 7, workspace, 7
          bind = $mainMod, 8, workspace, 8
          bind = $mainMod, 9, workspace, 9
          bind = $mainMod, 0, workspace, 10

          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          bind = $mainMod SHIFT, 1, movetoworkspace, 1
          bind = $mainMod SHIFT, 2, movetoworkspace, 2
          bind = $mainMod SHIFT, 3, movetoworkspace, 3
          bind = $mainMod SHIFT, 4, movetoworkspace, 4
          bind = $mainMod SHIFT, 5, movetoworkspace, 5
          bind = $mainMod SHIFT, 6, movetoworkspace, 6
          bind = $mainMod SHIFT, 7, movetoworkspace, 7
          bind = $mainMod SHIFT, 8, movetoworkspace, 8
          bind = $mainMod SHIFT, 9, movetoworkspace, 9
          bind = $mainMod SHIFT, 0, movetoworkspace, 10

          # Example special workspace (scratchpad)
          bind = $mainMod, S, togglespecialworkspace, magic
          bind = $mainMod SHIFT, S, movetoworkspace, special:magic

          # Scroll through existing workspaces with mainMod + scroll
          bind = $mainMod, mouse_down, workspace, e+1
          bind = $mainMod, mouse_up, workspace, e-1

          # Move/resize windows with mainMod + LMB/RMB and dragging
          bindm = $mainMod, mouse:272, movewindow
          bindm = $mainMod, mouse:273, resizewindow


          # Bind resize submap to resize window with arrow keys
          #bind = ALT, R, submap, resize

          # Enter resize submap
          #submap = resize

          # Resize active window with arrow keys while in resize submap
          #binde = , left, resizeactive, -10 0
          #binde = , right, resizeactive, 10 0
          #binde = , up, resizeactive, 0 -10
          #binde = , down, resizeactive, 0 10

          # Bind resize submap to ESCAPE key
          #bind = , ESCAPE, submap, reset

          # Reset the submap and return to global
          #submap = reset


          ##############################
          ### WINDOWS AND WORKSPACES ###
          ##############################

          # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
          # See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules

          # Example windowrule v1
          # windowrule = float, ^(kitty)$
          # Example windowrule v2
          # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$

          windowrulev2 = suppressevent maximize, class:.* # You'll probably like this.

          # Assign apps to workspaces
          windowrulev2 = workspace 1, class:^(kitty)$
          windowrulev2 = workspace 2, class:^(firefox)$

          # Prevent idle from starting if fullscreen/media apps are in use
          windowrulev2 = idleinhibit fullscreen, fullscreen:1
          windowrulev2 = idleinhibit always, title:^(Youtube)$
          #windowrulev2 = idleinhibit always, class:^(spotify)$
        '';
      };

      # Create hyprland pywal template
      xdg.configFile."wal/templates/colors-hyprland.conf".source = ./colors-hyprland.conf;
    };
  };

}
