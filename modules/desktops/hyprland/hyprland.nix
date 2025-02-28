{
  cfgOpts,
  lib,
  myUser,
  nixPath,
  pkgs,
  ...
}: let
  cfg = cfgOpts.desktops.hyprland;

  wallpaper = {
    dir = "${nixPath}/assets/wallpapers";
    day = "${wallpaper.dir}/blobs-l.png";
    night = "${wallpaper.dir}/blobs-d.png";
  };
in {
  config = lib.mkIf (cfg.enable) {
    home-manager.users.${myUser} = { lib, ... }: let
      hyprApps = cfg.hyprApps;
    in {
      wayland.windowManager.hyprland = {
        enable = true;
        systemd.variables = [ "--all" ];
        xwayland.enable = true;

        settings = let
          # Sets "Windows" key as main modifier
          mainMod = "SUPER";
        in {
          # Import optional color schemes
          #source = "/home/${myUser}/.cache/wal/colors-hyprland.conf";

          ################
          ### MONITORS ###
          ################
          # https://wiki.hyprland.org/Configuring/Monitors/
          # 'hyprctl monitors all' - "name, widthxheight@rate, position, scale"
          monitor = lib.mkDefault [ ", preferred, auto, auto" ];


          #################
          ### AUTOSTART ###
          #################
          # Autostart necessary processes (like notifications daemons, status bars, etc.)
          exec-once = [
            "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
            "${hyprApps.swww-daemon} & sleep 1 & ${hyprApps.swww} img ${wallpaper.day}"
            #"${hyprApps.waybar}"
            #"${hyprApps.nm-applet} --indicator"

            #exec-once = swww init & wal -R & waybar --config ~/.config/waybar/config.jsonc & mako --config ~/.config/mako/config & nm-applet --indicator
            #exec-once = wl-paste --type text --watch cliphist store  # Stores only text data
            #exec-once = wl-paste --type image --watch cliphist store  # Stores only image data
            #exec-once = ~/.config/hypr/scripts/polkit-kde-agent.sh  # Initialize authentication agent
            #exec-once = ~/.config/hypr/scripts/idle.sh  # Screen locking/timeout
            #exec-once = ~/.config/hypr/scripts/themes.sh  # Set cursors, icons, themes
            #exec-once = ~/.config/hypr/scripts/wallpaper.sh  # Set wallpaper

            # Silently start Firefox on ws2 at login
            #"[workspace 2 silent] firefox"
          ];
          #exec = [ ];


          #############################
          ### ENVIRONMENT VARIABLES ###
          #############################
          # https://wiki.hyprland.org/Configuring/Environment-variables/
          #env = [
            #"XCURSOR_SIZE,24"
            #"HYPRCURSOR_SIZE,24"
          #];


          #####################
          ### LOOK AND FEEL ###
          #####################
          # https://wiki.hyprland.org/Configuring/Variables/#general
          general = {
            # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
              allow_tearing = false;
            border_size = 2;
            # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
              "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
              "col.inactive_border" = "rgba(595959aa)";
            gaps_in = 5;
            gaps_out = 5;
            layout = "dwindle";
            # Set to true enable resizing windows by clicking and dragging on borders and gaps
              resize_on_border = true;
          };

          # https://wiki.hyprland.org/Configuring/Variables/#decoration
          decoration = {
            drop_shadow = true;

            # Change transparency of focused and unfocused windows
            active_opacity = 0.9;
            inactive_opacity = 0.75;

            rounding = 10;

            shadow_range = 4;
            shadow_render_power = 3;
            "col.shadow" = "rgba(1a1a1aee)";

            # https://wiki.hyprland.org/Configuring/Variables/#blur
            blur = {
              enabled = true;
              new_optimizations = true;
              passes = 1;
              size = 3;
              vibrancy = 0.1696;
            };
          };

          # https://wiki.hyprland.org/Configuring/Variables/#animations
          animations  = {
            enabled = true;
            # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
            bezier = [
              "myBezier, 0.05, 0.9, 0.1, 1.05"
            ];

            animation = [
              "border, 1, 10, default"
              "borderangle, 1, 8, default"
              "fade, 1, 7, default"
              "windows, 1, 7, myBezier"
              "windowsOut, 1, 7, default, popin 80%"
              "workspaces, 1, 6, default"
            ];
          };

          # https://wiki.hyprland.org/Configuring/Dwindle-Layout/
          dwindle = {
            # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
            pseudotile = true;
            # You probably want this
            preserve_split = true;
          };

          # https://wiki.hyprland.org/Configuring/Master-Layout/
          master.new_status = "master";

          # https://wiki.hyprland.org/Configuring/Variables/#misc
          misc = {
              # Set to 0 or 1 to disable the anime mascot wallpapers
              force_default_wallpaper = -1;
              # If true disables the random hyprland logo / anime girl background. :(
              disable_hyprland_logo = true;
          };


          #############
          ### INPUT ###
          #############
          # https://wiki.hyprland.org/Configuring/Variables/#input
          input = {
            follow_mouse = 1;
            kb_layout = "us";
            kb_variant = "";
            kb_model = "";
            kb_options = "";
            kb_rules = "";

            # -1.0 - 1.0, 0 means no modification
            sensitivity = 0;

            touchpad = {
              disable_while_typing = true;
              drag_lock = true;
              natural_scroll = true;
              tap-to-click = true;
              tap-and-drag = true;
            };
          };

          # https://wiki.hyprland.org/Configuring/Variables/#cursor
          cursor.no_hardware_cursors = true;

          # https://wiki.hyprland.org/Configuring/Variables/#gestures
          gestures = {
              workspace_swipe = true;
              workspace_swipe_fingers = 3;
          };

          # Example per-device config
          # https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs
          #device = {
              #name = "";
              #sensitivity = -0.5;
          #};


          ####################
          ### KEYBINDINGSS ###
          ####################
          # https://wiki.hyprland.org/Configuring/Binds/
          # Use 'wev' to determine unknown keys
          bind = [
            # Scroll through workspaces
            "${mainMod}, TAB, workspace, e+1"
            "${mainMod}, Q, killactive,"
            "${mainMod}, W, exec, ${hyprApps.firefox}"
            "${mainMod}, E, exec, ${hyprApps.fileManager}"
            #"${mainMod}, R, exec, rofi -show drun"
            "${mainMod}, T, exec, ${hyprApps.terminal}"
            "${mainMod}, P, pseudo," # dwindle
            "${mainMod}, D, exec, ${hyprApps.wofi} --show drun"
            "${mainMod}, F, fullscreen,"
            "${mainMod}, J, togglesplit," # dwindle
            #"${mainMod}, L, exec, ~/.config/hypr/scripts/lock_fade.sh"
            "${mainMod}, RETURN, exec, ${hyprApps.terminal}"
            #"${mainMod}, V, exec, ${hyprApps.cliphist} list | ${hyprApps.wofi} --dmenu | ${hyprApps.cliphist} decode | ${hyprApps.wl-copy}"
            #"${mainMod}, V, exec, ${cliphist} list | rofi --dmenu | ${cliphist} decode | ${wl-copy}"
            "${mainMod}, M, exit,"
            ", PRINT, exec, ${hyprApps.grim} -l 0 - | ${hyprApps.wl-copy}"
            "${mainMod}, PRINT, exec, ${hyprApps.grim} -l 0 -g \"$(${hyprApps.slurp})\" - | ${hyprApps.wl-copy}"
            "${mainMod} SHIFT, F, togglefloating,"
            #"${mainMod} SHIFT, L, exec, nwg-bar -i \"96\""
            "${mainMod} ALT, R, exec, pkill -SIGUSR2 ${hyprApps.waybar}"

            # Move focus w/ mainMod + arrow keys
            "${mainMod}, left, movefocus, l"
            "${mainMod}, right, movefocus, r"
            "${mainMod}, up, movefocus, u"
            "${mainMod}, down, movefocus, d"

            # Resize windows w/ mainMod + SHIFT + arrow keys
            "${mainMod} SHIFT, left, resizeactive, -10 0"
            "${mainMod} SHIFT, right, resizeactive, 10 0"
            "${mainMod} SHIFT, up, resizeactive, 0 -10"
            "${mainMod} SHIFT, down, resizeactive, 0 10"

            # Switch workspaces w/ mainMod + [0-9]
            "${mainMod}, 1, workspace, 1"
            "${mainMod}, 2, workspace, 2"
            "${mainMod}, 3, workspace, 3"
            "${mainMod}, 4, workspace, 4"
            "${mainMod}, 5, workspace, 5"
            "${mainMod}, 6, workspace, 6"
            "${mainMod}, 7, workspace, 7"
            "${mainMod}, 8, workspace, 8"
            "${mainMod}, 9, workspace, 9"
            "${mainMod}, 0, workspace, 10"

            # Move active window to a workspace w/ mainMod + SHIFT + [0-9]
            "${mainMod} SHIFT, 1, movetoworkspace, 1"
            "${mainMod} SHIFT, 2, movetoworkspace, 2"
            "${mainMod} SHIFT, 3, movetoworkspace, 3"
            "${mainMod} SHIFT, 4, movetoworkspace, 4"
            "${mainMod} SHIFT, 5, movetoworkspace, 5"
            "${mainMod} SHIFT, 6, movetoworkspace, 6"
            "${mainMod} SHIFT, 7, movetoworkspace, 7"
            "${mainMod} SHIFT, 8, movetoworkspace, 8"
            "${mainMod} SHIFT, 9, movetoworkspace, 9"
            "${mainMod} SHIFT, 0, movetoworkspace, 10"

            # Example special workspace (scratchpad)
            "${mainMod}, S, togglespecialworkspace, magic"
            "${mainMod} SHIFT, S, movetoworkspace, special:magic"

            # Scroll through existing workspaces w/ mainMod + scroll
            "${mainMod}, mouse_down, workspace, e+1"
            "${mainMod}, mouse_up, workspace, e-1"
          ];

          # Bind resize submap to resize window w/ arrow keys
          #bind = ALT, R, submap, resize
          # Enter resize submap
          #submap = resize

          # Resize active window w/ arrow keys while in resize submap
          #binde = , left, resizeactive, -10 0
          #binde = , right, resizeactive, 10 0
          #binde = , up, resizeactive, 0 -10
          #binde = , down, resizeactive, 0 10

          # Bind resize submap to ESCAPE key
          #bind = , ESCAPE, submap, reset
          # Reset the submap and return to global
          #submap = reset

          # Move/resize windows w/ mainMod + LMB/RMB and dragging
          bindm = [
            "${mainMod}, mouse:272, movewindow"
            "${mainMod}, mouse:273, resizewindow"
          ];


          ##############################
          ### WINDOWS AND WORKSPACES ###
          ##############################
          # https://wiki.hyprland.org/Configuring/Window-Rules/
          # https://wiki.hyprland.org/Configuring/Workspace-Rules/

          # Example windowrule v1
          # windowrule = float, ^(kitty)$
          # Example windowrule v2
          # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$

          windowrulev2 = [
            "suppressevent maximize, class:.*" # You'll probably like this.

            # Assign apps to workspaces
            #"workspace 1, class:^(kitty)$"
            "workspace 2, class:^(firefox)$"

            # Prevent idle from starting if fullscreen/media apps are in use
            "idleinhibit fullscreen, fullscreen:1"
            "idleinhibit always, title:^(Youtube)$"
            #"idleinhibit always, class:^(spotify)$"
          ];
        };

        #extraConfig = '''';
      };
    };
  };
}
