{ config, lib, pkgs, vars, ... }: let
  cfg = config.myOptions.gaming;
  host = config.myHosts;
in {
  options.myOptions.gaming.enable = lib.mkEnableOption "Gaming";

  config = lib.mkIf (cfg.enable) {
    boot.kernel.sysctl = {
      # Faster timeout so games can reuse their TCP ports
      "net.ipv4.tcp_fin_timeout" = 5;
      # Increase stability/performance of games
      "vm.max_map_count" = lib.mkForce 2147483642;
    };

    environment.systemPackages = with pkgs; let
      gs-renice-pkg = pkgs.writeShellScriptBin "gs-renice" ''
        (sleep 1; pgrep gamescope | xargs renice -n -20 -p)&
        exec gamescope "$@"
      '';

      lutris-pkg = pkgs.lutris.override {
        extraLibraries = pkgs: (with config.hardware.graphics; if pkgs.hostPlatform.is64bit
          then extraPackages
          else extraPackages32
        );
        extraPkgs = pkgs: with pkgs; [
          dxvk
          vkd3d
          winetricks
          # wineWow has both x86/64 - stable, staging, or wayland
          wineWowPackages.wayland
        ];
      };
    in [
      gamescope-wsi   # Gamescope with WSI (breaks if declared in gamescope.package)
      gs-renice-pkg   # Builds 'gs-renice' command to add to game launch options
      heroic          # Game launcher - Epic, GOG, Prime
      jdk             # Java games
      lutris-pkg      # Game launcher - Epic, GOG, Humble Bundle, Steam
      protonplus      # Proton-GE updater
    ];

    environment.variables."STEAM_EXTRA_COMPAT_TOOLS_PATHS" = "/home/${vars.user}/.steam/steam/compatibilitytools.d";

    home-manager.users.${vars.user} = {
      home.file = {
        # Custom steam.desktop file with host's scaling applied
        /*".local/share/applications/steam.desktop" = let steam-pkg = config.programs.steam.package; in {
          executable = true;
          text = lib.replaceStrings [ "Exec=steam %U" ] [ "Exec=${lib.getExe steam-pkg} -forcedesktopscaling=${host.scale} %U" ] (lib.fileContents "${pkgs.steamPackages.steam}/share/applications/steam.desktop");
        };*/

        "Games/Severed_Chains_Linux/launch" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            export LD_LIBRARY_PATH=${pkgs.libGL}/lib:$LD_LIBRARY_PATH
            cd ~/Games/Severed_Chains_Linux/
            ${lib.getExe' pkgs.jdk "java"} -cp "lod-game-cbb72c363c4425e53434bd75874d9d697a6cdda2.jar:libs/*" legend.game.Main -ea
          '';
        };
      };

      programs.mangohud = {
        enable = true;
        enableSessionWide = false;
        settings = with lib; {
          ### Performance ###
          fps_limit = host.refresh;
          fps_limit_method = "late";
          vsync = 0;
          gl_vsync = -1;
          ### Visual ###
          time_no_label = true;
          gpu_text = "GPU";
          gpu_stats = true;
          gpu_load_change = true;
          gpu_load_value = "50,90";
          gpu_load_color = mkDefault "FFFFFF,FFAA7F,CC0000";
          gpu_temp = true;
          gpu_power = true;
          cpu_text = "CPU";
          cpu_stats = true;
          cpu_load_change = true;
          cpu_load_value = "50,90";
          cpu_load_color = mkDefault "FFFFFF,FFAA7F,CC0000";
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
          background_alpha = mkForce 0.4;
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
            # Scheduler policy
            softrealtime = "auto";
          };
        };
      };

      gamescope = {
        enable = true;
        args = [
          "-W ${host.width}"
          "-H ${host.height}"
          "-r ${host.refresh}"                 # Focused refresh rate
          "-o 30"                              # Unfocused refresh rate
          "--adaptive-sync"                    # VRR (if available)
          "--framerate-limit ${host.refresh}"  # Sync framerate to refresh rate
          "--rt"                               # Real-time scheduling
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
          extraEnv.LD_PRELOAD = "${lib.getLib pkgs.gamemode}/lib/libgamemode.so";
          extraPkgs = pkgs: with pkgs; [
            # Gamescope fixes for undefined symbols in X11 session
            keyutils
            libkrb5
            libpng
            libpulseaudio
            libvorbis
            stdenv.cc.cc.lib
            xorg.libXcursor
            xorg.libXi
            xorg.libXinerama
            xorg.libXScrnSaver
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

    users.users.${vars.user}.extraGroups = [ "gamemode" ];

  };
}
