{ config, inputs, lib, pkgs, vars, ... }: with lib;
let
  hyprland-flake = inputs.hyprland.packages.${pkgsPsystem}; 
  wall_dir = "/persist/etc/nixos/wallpapers";
  day_wall = "${wall_dir}/blobs-l.png";
  night_wall = "${wall_dir}/blobs-d.png";
in {
  imports = [
    inputs.hyprland.homeManagerModules.default
  ];

  options.hyprland.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.hyprland.enable) {
    #imports = [
      #inputs.hyprland.homeManagerModules.default
    #];

    environment.sessionVariables = {
      # Hint electron apps to use Wayland
      NIXOS_OZONE_WL = "1";
      # If the cursor becomes invisible - VMWare?
      WLR_NO_HARDWARE_CURSORS = "1";
      # VMware?
      WLR_RENDERER_ALLOW_SOFTWARE = "1";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";

      XCURSOR_SIZE = "24";
      #XCURSOR_THEME = "Catppuccin-Frappe-Mauve-Cursors";
      GDK_SCALE = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland;xcb";
      #GTK_THEME = "Catppuccin-Frappe-Standard-Mauve-Dark";
      #QT_QPA_PLATFORMTHEME = "Catppuccin-Frappe-Standard-Mauve-Dark";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    };

    environment.systemPackages = with pkgs; [
    # Application Launcher
      rofi-wayland                #
      #wofi                       #
      #iw                         # wireless config for rofi-wifi script
      #bc                         # calculator for rofi-wifi script

    # Authorization Agent
      polkit_gnome                #

    # Clipboard
      cliphist                    # Save clipboard history after closing apps

    # File Manager
      gnome.file-roller           # Archive GUI manager
      pcmanfm                     #

    # Hardware
      brightnessctl               #
      pw-volume                   # Pipewire control

    # Locking
      swayidle                    #
      swaylock-effects            #

    # Login Manager
      greetd.tuigreet             # TTY-like greeter

    # Notification
      mako                        #

    # Screenshot
      grim                        #
      slurp                       #

    # Session Management
      nwg-bar                     #
      wlogout                     #

    # Status bar
      eww-wayland                 #
      #unstable.waybar            #
      #networkmanagerapplet        # Show network tray icon (nm-applet --indicator)

    # Wallpaper
      #hyprpaper                  #
      swww                        # Manager capable of GIFs

    # Wayland
      libsForQt5.qt5.qtwayland    # QT5 Wayland support
      meson                       #
      qt6.qtwayland               # QT6 Wayland support
      wayland-protocols           #
      wayland-utils               #
      wev                         # Keymapper
      wlroots                     # Wayland compositor library
      xwayland                    # Interface X11 apps with Wayland
    ];

    programs = {
      hyprland = {
        enable = true;
        package = hyprland-flake.hyprland;
        # X11 compatability
        xwayland.enable = true;
      };

      regreet = {
        enable = false;
        #settings = /home/${vars.user}/.config/regreet/regreet.toml;
        settings = "./regreet.toml";
      };

      waybar = {
        enable = false;
        package = pkgs.waybar;
      };
    };

    security = {
      # Enable keyboard input after locking
      pam.services.swaylock = {};
      polkit.enable = true;
    };

    services = {
      dbus.enable = true;

      greetd = {
        enable = true;
        package = pkgs.greetd.tuigreet;
        settings = {
          default_session = initial_session;
            # Auto login
          initial_session = {
            # Regreet command
            #command = "Hyprland";
              #or
            #command = "${pkgs.hyprland}/bin/Hyprland";
            # Tuigreet command
            command = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --remember-user-session --time --cmd ${pkgs.hyprland}/bin/Hyprland";
            user = "${vars.user}";
          };
        };
      };

      network-manager-applet.enable = true;

      xserver.excludePackages = with pkgs; [
        xterm
      ];
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;

      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        #xdg-desktop-portal-wlr
      ];
    };

    home-manager.users.${vars.user} = { lib, ... }: {
      programs.bash.initExtra = ''
        if command -v wal > /dev/null 2>&1 && [ "$TERM" = "${vars.terminal}" ]; then
          wal -Rqe
        fi
      '';

   /* qt = {
        enable = true;
      }; */

      #services.mako.enable = true;

      wayland.windowManager.hyprland = {
        enable = true;
        # Package doesn't need to be declared since done in the system - use null instead?
        #package = hyprland-flake.hyprland;
        package = null;
        xwayland.enable = true;

        extraConfig = ''
          #
          # Please note not all available settings / options are set here.
          # For a full list, see the wiki
          #

          # See https://wiki.hyprland.org/Configuring/Monitors/
          # hyprctl monitors all
          #monitor=name,resolution@htz,position,scale
          #monitor=,preferred,auto,auto
          #monitor=eDP-1,1920x1080@60,0x0,1

          # See https://wiki.hyprland.org/Configuring/Keywords/ for more

          # Execute your favorite apps at launch
          # exec-once = waybar & hyprpaper & firefox
          #exec-once = swww init & wal -R & waybar --config ~/.config/waybar/config.jsonc & mako --config ~/.config/mako/config & nm-applet --indicator
          #exec-once = wl-paste --type text --watch cliphist store  # Stores only text data
          #exec-once = wl-paste --type image --watch cliphist store  # Stores only image data
          #exec-once = ~/.config/hypr/scripts/polkit-kde-agent.sh  # Initialize authentication agent
          exec-once = ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
          #exec-once = ~/.config/hypr/scripts/idle.sh  # Screen locking/timeout
          #exec-once = ~/.config/hypr/scripts/themes.sh  # Set cursors, icons, themes
          #exec-once = ~/.config/hypr/scripts/wallpaper.sh  # Set wallpaper

          # Source a file (multi-file configs)
          # source = ~/.config/hypr/myColors.conf
          # source = ~/.config/hypr/themes/frappe.conf
          source = /home/${vars.user}/.cache/wal/colors-hyprland.conf

          # Some default env vars.
          env = XDG_CURRENT_DESKTOP,Hyprland
          env = XDG_SESSION_TYPE,wayland
          env = XDG_SESSION_DESKTOP,Hyprland

          # For all categories, see https://wiki.hyprland.org/Configuring/Variables/
          input {
              kb_layout = us
              kb_variant =
              kb_model =
              kb_options =
              kb_rules =

              follow_mouse = 1

              touchpad {
                  disable_while_typing = yes
                  natural_scroll = yes
                  tap-to-click = yes
                  tap-and-drag = yes
                  drag_lock = yes
              }

              sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
          }

          general {
              # See https://wiki.hyprland.org/Configuring/Variables/ for more

              gaps_in = 5
              gaps_out = 10
              border_size = 2
              # col.active_border = $mauve $sapphire 135deg
              # col.inactive_border = $surface2
              #col.active_border = $color11 # $color## 135deg
              #col.inactive_border = $color8 # or $background
              col.active_border = rgb(FFFFFF)
              col.inactive_border = rgb(000FFF)
              layout = dwindle
          }

          decoration {
              # See https://wiki.hyprland.org/Configuring/Variables/ for more

              rounding = 10
              blur = yes
              blur_size = 3
              blur_passes = 1
              blur_new_optimizations = on

              drop_shadow = yes
              shadow_range = 4
              shadow_render_power = 3
              col.shadow = rgba(1a1a1aee)
          }

          animations {
              enabled = yes

              # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

              bezier = myBezier, 0.05, 0.9, 0.1, 1.05

              animation = windows, 1, 7, myBezier
              animation = windowsOut, 1, 7, default, popin 80%
              animation = border, 1, 10, default
              animation = borderangle, 1, 8, default
              animation = fade, 1, 7, default
              animation = workspaces, 1, 6, default
          }

          dwindle {
              # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
              pseudotile = yes # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
              preserve_split = yes # you probably want this
          }

          master {
              # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
              new_is_master = true
          }

          gestures {
              # See https://wiki.hyprland.org/Configuring/Variables/ for more
              workspace_swipe = on
              workspace_swipe_fingers = 3
          }

          misc {
            disable_hyprland_logo = yes
          }

          # Example per-device config
          # See https://wiki.hyprland.org/Configuring/Keywords/#executing for more
          device:epic-mouse-v1 {
              sensitivity = -0.5
          }

          # Example windowrule v1
          # windowrule = float, ^(kitty)$
          # Example windowrule v2
          # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$
          # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
          windowrulev2 = workspace 1, class:^(kitty)$
          windowrulev2 = workspace 2, class:^(firefox)$

          # Prevent swayidle from starting if fullscreen/media apps are in use
          windowrulev2 = idleinhibit fullscreen, fullscreen:1
          windowrulev2 = idleinhibit always, title:^(Youtube)$
          #windowrulev2 = idleinhibit always, class:^(spotify)$

          # See https://wiki.hyprland.org/Configuring/Keywords/ for more
          $mainMod = SUPER

          # Function key binds
          #bind = , XF86AudioMute, exec, amixer sset Master toggle
          #bind = , XF86AudioLowerVolume, exec, amixer sset Master 5%-
          #bind = , XF86AudioRaiseVolume, exec, amixer sset Master 5%+
          #bind = , XF86, exec, amixer sset Capture toggle  # Command works, mic/button disabled in firmware?
          #bind = , XF86MonBrightnessDown, exec, brightnessctl s 10%-
          #bind = , XF86MonBrightnessUp, exec, brightnessctl s +10%
          #bind = , XF86Display, , # Presentation mode?
          #bind = , XF86WLAN, , # Disables wifi by default
          #bind = , XF86Tools, , # Settings shortcut?
          #bind = , XF86Search, , # rofi search?
          #bind = , XF86LaunchA, exec, rofi -show drun  # rofi launcher
          #bind = , XF86Explorer, exec, kitty lf

          # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
          # Use wev to determine unknown keys
          bind = $mainMod, RETURN, exec, kitty
          #bind = $mainMod, D, exec, wofi #--show=drun
          bind = $mainMod, E, exec, kitty lf
          bind = $mainMod, F, togglefloating,
          bind = $mainMod, J, togglesplit, # dwindle
          #bind = $mainMod, L, exec, ~/.config/hypr/scripts/lock_fade.sh
          bind = $mainMod, M, exit,
          bind = $mainMod, P, pseudo, # dwindle
          bind = $mainMod, Q, killactive,
          #bind = $mainMod, R, exec, rofi -show drun
          #bind = $mainMod, V, exec, cliphist list | rofi --dmenu | cliphist decode | wl-copy
          #bind = $mainMod, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy
          #bind = $mainMod, W, exec, firefox
          #bind = , PRINT, exec, grim -l 0 - | wl-copy
          #bind = $mainMod, PRINT, exec, grim -l 0 -g "$(slurp)" - | wl-copy

          bind = $mainMod, TAB, workspace, e+1  # Scroll through workspaces
          bind = $mainMod SHIFT, F, fullscreen,
          #bind = $mainMod SHIFT, L, exec, nwg-bar -i "96"
          bind = $mainMod ALT, R, exec, pkill -SIGUSR2 waybar

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
        '';
      };

      # Create hyprland pywal template
      xdg.configFile."wal/templates/colors-hyprland.conf".source = ./colors-hyprland.conf;
    };
  };

}
