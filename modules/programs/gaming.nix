{
  config,
  lib,
  pkgs,
  cfgHosts,
  cfgOpts,
  myUser,
  ...
}: let
  cfg = cfgOpts.gaming;
in {
  options.myOptions.gaming.enable = lib.mkEnableOption "Gaming";

  config = lib.mkIf (cfg.enable) {
    boot.kernel.sysctl = {
      # Faster timeout so games can reuse their TCP ports
      "net.ipv4.tcp_fin_timeout" = 5;
      # Increase stability/performance of games
      "vm.max_map_count" = lib.mkForce 2147483642;
    };

    environment = {
      systemPackages = let
        gs-renice-pkg = pkgs.writeShellScriptBin "gs-renice" ''
          (sleep 1; pgrep gamescope | xargs renice -n -20 -p)&
          exec gamescope "$@"
        '';

        lutris-pkg = pkgs.lutris.override {
          extraLibraries = pkgs: (
            if (pkgs.hostPlatform.is64bit)
              then config.hardware.graphics.extraPackages
            else config.hardware.graphics.extraPackages32
          );
          extraPkgs = pkgs: builtins.attrValues {
            inherit (pkgs)
              dxvk
              vkd3d
              winetricks
            ;
          } ++ [
            # wineWow has both x86/64 - stable, staging, or wayland
            pkgs.wineWowPackages.wayland
          ];
        };
      in [
        gs-renice-pkg     # Builds 'gs-renice' command to add to game launch options
        lutris-pkg        # Game launcher - Epic, GOG, Humble Bundle, Steam
      ] ++ builtins.attrValues {
        inherit (pkgs)
          gamescope-wsi   # Gamescope w/ WSI (breaks if declared in gamescope.package)
          heroic          # Game launcher - Epic, GOG, Prime
          jdk             # Java games
          protonplus      # Proton-GE updater
        ;
      };

      variables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${myUser}/.steam/steam/compatibilitytools.d";
        #STEAM_FORCE_DESKTOPUI_SCALING = "${builtins.toString cfgHosts.scale}";
      };
    };

    home-manager.users.${myUser} = {
      home.file = {
        "Games/Severed_Chains_Linux/launch" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${pkgs.libGL}/lib
            cd ~/Games/Severed_Chains_Linux/
            ${lib.getExe' pkgs.jdk "java"} -cp "lod-game-cbb72c363c4425e53434bd75874d9d697a6cdda2.jar:libs/*" legend.game.Main -ea
          '';
        };
      };

      programs.mangohud = {
        enable = true;
        enableSessionWide = false;
        settings = {
          ### Performance ###
          fps_limit = cfgHosts.refresh;
          fps_limit_method = "late";
          vsync = 0;
          gl_vsync = -1;
          ### Visual ###
          time_no_label = true;
          gpu_text = "GPU";
          gpu_stats = true;
          gpu_load_change = true;
          gpu_load_value = "50,90";
          gpu_load_color = lib.mkDefault "FFFFFF,FFAA7F,CC0000";
          gpu_temp = true;
          gpu_power = true;
          cpu_text = "CPU";
          cpu_stats = true;
          cpu_load_change = true;
          cpu_load_value = "50,90";
          cpu_load_color = lib.mkDefault "FFFFFF,FFAA7F,CC0000";
          cpu_temp = true;
          cpu_power = true;
          vram = true;
          ram = true;
          fps = true;
          vulkan_driver = true;
          # Display GameMode status
          gamemode = true;
          # Display Gamescope options status
          fsr = true;
          hdr = true;
          # Display above Steam UI
          mangoapp_steam = false;
          position = "top-left";
          round_corners = 10;
          table_columns = 4;
          background_alpha = lib.mkForce 0.4;
          ### Interaction ###
          toggle_hud = "Shift_R+F12";
        };
      };
    };

    programs = {
      # Steam: Right-click game -> Properties -> Launch options: 'gs-renice -- mangohud gamemoderun %command%'
      # Lutris: Preferences -> Global options -> CPU -> Enable Feral GameMode
      gamemode = {
        enable = true;
        enableRenice = true;
        settings = {
          # Currently hiding Gamemode notifications
          #custom.start = "${lib.getExe pkgs.libnotify} -a 'GameMode' -i 'input-gaming' 'GameMode Activated'";
          #custom.end = "${lib.getExe pkgs.libnotify} -a 'GameMode' -i 'input-gaming' 'GameMode Deactivated'";
          general = {
            # Prevents errors when screensaver not installed
            inhibit_screensaver = 0;
            # Game process priority
            renice = 20;
            # Reaper checks every 5 secs for updates
            reaper_freq = 5;
            # Scheduler policy
            softrealtime = "auto";
          };
        };
      };

      gamescope = {
        enable = true;
        args = [
          "-W ${builtins.toString cfgHosts.width}"                  # Output width
          "-H ${builtins.toString cfgHosts.height}"                 # Output height
          #"-w ${builtins.toString cfgHosts.width}"                  # Game width
          #"-h ${builtins.toString cfgHosts.height}"                 # Game height
          "-r ${builtins.toString cfgHosts.refresh}"                # Refresh rate
          "-o 30"                                                   # Unfocused refresh rate
          "-b"                                                      # Borderless window
          #"-f"                                                      # Fullscreen window
          #"--adaptive-sync"                                         # VRR (if available)
          "--framerate-limit ${builtins.toString cfgHosts.refresh}" # Sync framerate to refresh rate
          "--rt"                                                    # Real-time scheduling
        ];
        # capSysNice currently stops games from launching - "failed to inherit capabilities: Operation not permitted"
          # Current workaround is using 'gs-renice' to replace gamescope in launch options mentioned above
        #capSysNice = true;
      };

      steam = {
        enable = true;
        extest.enable = true;
        #extraCompatPackages = [ pkgs.proton-ge-bin ];
        gamescopeSession.enable = false;

        # Firewall options
        dedicatedServer.openFirewall = false;
        localNetworkGameTransfers.openFirewall = true;
        remotePlay.openFirewall = true;

        package = pkgs.steam.override {
          extraEnv.LD_PRELOAD = "${pkgs.gamemode.lib}/lib/libgamemode.so";
          extraPkgs = pkgs: builtins.attrValues {
            # Gamescope fixes for undefined symbols in X11 session
            inherit (pkgs)
              keyutils
              libkrb5
              libpng
              libpulseaudio
              libvorbis
            ;
            inherit (pkgs.xorg)
              libXcursor
              libXi
              libXinerama
              libXScrnSaver
            ;
          } ++ [
            pkgs.stdenv.cc.cc.lib
          ];
        };
      };
    };

    # Gamemode process priority renice fix
    security.pam.loginLimits = [{
      domain = "@gamemode";
      type = "-";
      item = "nice";
      value = -20;  # Range from -20 to 19
    }];

    users.users.${myUser}.extraGroups = [ "gamemode" ];
  };
}
