{
  cfgOpts,
  config,
  lib,
  myUser,
  ...
}: let
  cfg = cfgOpts.desktops.hyprland;
in {
  config = lib.mkIf (cfg.enable) {
    home-manager.users.${myUser} = { lib, ... }: let
      hyprApps = cfg.hyprApps;
    in {
      programs.waybar = {
        enable = true;
        systemd = {
          enable = true;
          #target = "graphical-session.target";
        };
        settings = {
          mainBar = {
            # General Settings
            layer = "top";
            position = "top";
            height = 34;
            margin-top = 5;
            margin-bottom = 0;
            margin-left = 5;
            margin-right = 5;
            spacing = 1;
            reload_style_on_change = true;

            # Modules Left
            "modules-left" = [
              "custom/appmenu"
              "custom/spacer"
              "hyprland/workspaces"
              #"hyprland/window"
            ];

            # Modules Center
            "modules-center" = [
              "clock"
              #"custom/weather"
            ];

            # Modules Right
            "modules-right" = [
              "group/sensors"
              "keyboard-state"
              #"custom/cliphist"
              "tray"
              ] ++ lib.optionals (config.bluetooth.enable) [ "bluetooth" ] ++ [
              "wireplumber"
              "network"
              "group/battery"
              "custom/spacer"
              "custom/exit"
            ];


            # Application Launcher
            "custom/appmenu" = {
              format = "";
              #on-click = "rofi -show drun -replace";
              on-click = "${hyprApps.wofi} --show drun";
              on-click-right = "${hyprApps.nwg-bar} -i '96'";
              tooltip = false;
            };

            # Spacer
            "custom/spacer" = {
              format = " ";
              tooltip = false;
            };

            # Workspaces
            "hyprland/workspaces" = {
              active-only = false;
              all-outputs = true;
              format = "{id}";
              format-icons = {
                active = "";
                default = "";
                urgent = "";
              };
              on-click = "activate";
              persistent-workspaces = {
                "*" = 4;
              };
            };

            # Hyprland Window
            "hyprland/window" = {
              rewrite = {
                "(.*) - Brave" = "$1";
                "(.*) - Mozilla Firefox" = "$1";
              };
              separate-outputs = true;
            };

            # Clock
            "clock" = {
              format = "{:%a, %b %d  %H:%M (%Z)}";
              timezones = [
                "America/Chicago"
                "Europe/Tallinn"
                "Asia/Tokyo"
              ];
              #on-click = "${thunderbird} -calendar";
              tooltip = true;
              tooltip-format = "<tt><small>{calendar}</small></tt>";
              calendar = {
                mode = "month";
                #mode-mon-col = 3;
                format = {
                  #months = "";
                  #weeks = "";
                  #weekdays = "";
                  #days = "";
                  today = "<span><b><u>{}</u></b></span>";
                };
              };
              actions = {
                on-click-right = "tz_up";
                on-scroll-up = "shift_up";
                on-scroll-down = "shift_down";
              };
            };

            # Sensors group
            "group/sensors" = {
              orientation = "horizontal";
              modules = [
                "temperature#cpu"
                "temperature#gpu"
              ];
            };

            # Key Locks
            "keyboard-state" = {
              format = {
                capslock = "{icon}";
              };
              format-icons = {
                locked = "A";
                unlocked = "";
              };
              capslock = true;
            };

            # Clipboard
            "custom/cliphist" = {
              format = "";
              #on-click = "sleep 0.1 && ~/.config/scripts/cliphist.sh";
              tooltip = false;
            };

            # System Tray
            "tray" = {
              icon-size = 21;
              spacing = 10;
            };

            # Audio
            "wireplumber" = {
              format = "{icon}";
              format-icons = [ "󰕿" "󰖀" "󰕾" ];
              format-muted = "󰝟";
              on-click-right = "${hyprApps.pw-volume} mute toggle";
              on-scroll-up = "${hyprApps.pw-volume} change +5%";
              on-scroll-down = "${hyprApps.pw-volume} change -5%";
              reverse-scrolling = 1;
              tooltip = true;
              tooltip-format = "Volume: {volume}%";
              tooltip-muted = "Volume: Muted";
            };

            # Bluetooth
            "bluetooth" = lib.mkIf (config.bluetooth.enable) {
              format-disabled = "";
              format-off = "󰂲";
              format_on = "󰂯";
              format-connected = "󰂱";
              on-click = "${hyprApps.blueman}";
              tooltip = true;
              tooltip-format-off = "{status}";
              tooltip-format-on = "{status}";
              tooltip-format-connected = "{status} - {device_alias}";
              tooltip-format-connected-battery = "{status} - {device_alias}\nBattery: {device_battery_percentage}%";
            };

            # Network
            "network" = {
              interval = 5;
              format-ethernet = "";
              format-wifi = "";
              format-disconnected = "󰅛"; # An empty format will hide the module.
              #on-click = "${hyprApps.terminal} nmtui";
              on-click = "${hyprApps.nm-connect}";
              tooltip = true;
              tooltip-format-wifi = "   {essid}\n{frequency}GHz - Signal: {signalStrength}%\n{ifname} ({ipaddr}/{cidr})\n{bandwidthDownBytes}";
              tooltip-format-ethernet = "   {ifname} ({ipaddr}/{cidr})\n{bandwidthDownBytes}";
              tooltip-format-disconnected = "No network connection";
            };

            # Battery group
            "group/battery" = {
              orientation = "horizontal";
              modules = [
                "battery#bat0"
                "battery#bat1"
              ];
            };

            # Power Menu
            "custom/exit" = {
              format = "";
              on-click = "${hyprApps.nwg-bar}";
              tooltip = false;
            };
          };

          /*
          taskBar = {
            # General Settings
            layer = "top";
            position = "bottom";
            height = 24;
            margin-top = 0;
            margin-bottom = 10;
            margin-left = 5;
            margin-right = 5;
            spacing = 1;
            mode = "dock";
            #mode = "hide";
            reload_style_on_change = true;

            # Modules Center
            "modules-center" = [
              "wlr/taskbar"
            ];

            # Taskbar
            "wlr/taskbar" = {
              format = "{icon}";
              icon-size = 20;
              tooltip = true;
              tooltip-format = "{name} - {title}";
              on-click = "activate";
              on-click-middle = "minimize-raise";
              ignore-list = [ ];
              rewrite = {
                "Firefox Web Browser" = "Firefox";
              };
            };
          }; */
        };

        style = let
          waybarBg = "rgba(255,255,255,0.1)";
          moduleBg = "rgba(0,50,50,0.5)";
          wsActive = "rgba(0,50,50,0.75)";
          wsHover = "rgba(128,128,128,0.5)";
          fontColor = "#FFFFFF";
          moduleSpace = "5px";
        in ''
          * {
            color: ${fontColor};
            font-size: 13px;
            margin: 0px;
            padding: 0px;
          }

          window#waybar {
            background-color: ${waybarBg};
            border-radius: 20px;
          }

          .modules-left {
            margin: 2px 0;
          }

          .modules-center {
            background-color: ${moduleBg};
            border-radius: 10px;
            margin: 2px 0;
          }

          .modules-right {
            background-color: ${moduleBg};
            border-radius: 10px;
            margin: 2px 0;
          }

          #custom-appmenu {
            background-color: ${moduleBg};
            border-radius: 100px;
            font-size: 18px;
            padding: 0 13px 0 6px;
          }

          #custom-spacer {
          }

          #workspaces {
            border: 1px solid ${moduleBg};
            border-radius: 10px;
          }

          #workspaces button {
            background-color: ${moduleBg};
            border-radius: 0px;
            padding: 0 7px;
          }

          #workspaces button:first-child {
            border-radius: 10px 0 0 10px;
          }

          #workspaces button:last-child {
            border-radius: 0 10px 10px 0;
          }

          #workspaces button:hover {
            background: none;
            background-color: ${wsHover};
            border-color: transparent;
            box-shadow: none;
            text-shadow: none;
          }

          #workspaces button.active {
            background: transparent;
            /* background-color: ${wsActive}; */
            border: 1px solid ${fontColor};
            font-weight: bold;
          }

          #clock {
            padding: 0 8px;
          }

          #temperature.cpu {
            padding: 0 ${moduleSpace} 0 8px;
          }

          #temperature.gpu,
          #keyboard-state label.locked,
          #custom-cliphist,
          #tray,
          #bluetooth,
          #battery.bat0 {
            padding: 0 ${moduleSpace};
          }

          #wireplumber {
            font-size: 20px;
            padding: 0 ${moduleSpace};
          }

          #network {
            padding: 0 12px 0 ${moduleSpace};
          }

          #battery.bat1 {
            padding: 0 0 0 ${moduleSpace};
          }

          #custom-exit {
            padding-right: 13px;
          }
        '';
      };
    };
  };
}
