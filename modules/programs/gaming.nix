{ config, lib, pkgs, vars, ... }: with lib; {
  options.gaming.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.gaming.enable) {
    # Increase stability/performance of games
    boot.kernel.sysctl."vm.max_map_count" = mkForce 2147483642;

    environment.systemPackages = with pkgs; [
      heroic                            # Game launcher - Epic, GOG, Prime
      #playonlinux                      # GUI for Windows programs
      (lutris.override {                # Game launcher - Epic, GOG, Humble Bundle, Steam
        extraLibraries = pkgs: (with config.hardware.graphics; if pkgs.hostPlatform.is64bit then
          extraPackages
        else
          extraPackages32
        );
        extraPkgs = pkgs: with pkgs; [
          dxvk
          vkd3d
          winetricks
          # wineWow has both x86/64 - stable, staging, or wayland
          wineWowPackages.staging
        ];
      })
    ];

    home-manager.users.${vars.user} = {
      programs.mangohud = {
        enable = true;
        enableSessionWide = false;
        settings = {
          ### Performance ###
          fps_limit_method = "late";
          vsync = "0";
          gl_vsync = "-1";

          ### Visual ###
          time_no_label = true;

          gpu_text = "GPU";
          gpu_stats = true;
          gpu_load_change = true;
          gpu_load_value = "50,90";
          gpu_load_color = "FFFFFF,FFAA7F,CC0000";
          gpu_temp = true;
          gpu_power = true;

          cpu_text = "CPU";
          cpu_stats = true;
          cpu_load_change = true;
          cpu_load_value = "50,90";
          cpu_load_color = "FFFFFF,FFAA7F,CC0000";
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
          mangoapp_steam = true;

          position = "top-left";
          round_corners = 10;
          table_columns = 4;
          background_alpha = "0.4";

          ### Interaction ###
          toggle_hud = "Shift_R+F12";
        };
      };
    };

    programs = {
      # Better gaming performance
      # Steam: Right-click game -> Properties -> Launch options: gamemoderun gamescope -- mangohud %command%
      # Lutris: Preferences -> Global options -> CPU -> Enable Feral GameMode
      gamemode = {
        enable = true;
        settings = {
          custom = {
            start = "${pkgs.libnotify}/bin/notify-send -a 'GameMode' -i 'input-gaming' 'GameMode Activated'";
            end = "${pkgs.libnotify}/bin/notify-send -a 'GameMode' -i 'input-gaming' 'GameMode Deactivated'";
          };
          # Prevents errors when screensaver not installed
          general.inhibit_screensaver = 0;
        };
      };

      steam = {
        enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];

        # Firewall related
        dedicatedServer.openFirewall = false;
        localNetworkGameTransfers.openFirewall = true;
        remotePlay.openFirewall = true;
        
        package = pkgs.steam.override {
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

          extraProfile = let
            gmLib = "${lib.getLib(pkgs.gamemode)}/lib";
          in ''
            export LD_PRELOAD="${gmLib}/libgamemode.so:$LD_PRELOAD"
          '';
        };
      };
    };

  };
}
