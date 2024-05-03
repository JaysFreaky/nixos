{ config, lib, pkgs, vars, ... }:
with lib;
{
  options.gaming.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.gaming.enable) {
    # Increase stability/performance of games
    boot.kernel.sysctl."vm.max_map_count" = lib.mkForce 2147483642;

    environment.systemPackages = with pkgs; [
      corectrl                          # CPU/GPU undervolting
      gamescope-wsi                     # Required for HDR?
      #heroic                           # Game launcher - Epic, GOG, Prime
      lact                              # GPU controller
      #moonlight-qt                     # Remote streaming
      #playonlinux                      # GUI for Windows programs
      protonup-ng                       # CLI updater for ProtonGE | 'protonup'
      (lutris.override {                # Game launcher - Epic, GOG, Humble Bundle, Steam
        extraLibraries = pkgs: ( with config.hardware.opengl; if pkgs.hostPlatform.is64bit
          then extraPackages
          else extraPackages32
        );

        # Still determining which wine packages to use
        extraPkgs = pkgs: with pkgs; ( if pkgs.hostPlatform.is64bit
            then [ pkgs.wine64 ]
            else [ pkgs.wine ]
          ) ++ [
          dxvk
          vkd3d
          winetricks
        ];
      })
    ];

    environment.variables = {
      # Lutris feral gamemode enablement - pre v1.3
      #LD_PRELOAD = "$LD_PRELOAD:/nix/store/*-gamemode-*-lib/lib/libgamemodeauto.so";

      # ProtonGE path - pre proton-ge-bin
      #STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${vars.user}/.steam/root/compatibilitytools.d";
    };

    home-manager.users.${vars.user} = {
      programs.mangohud = {
        enable = true;
        enableSessionWide = false;

        settings = {
          time = true;
          gpu_stats = true;
          gpu_temp = true;
          gpu_power = true;
          #gpu_text = "GPU";
          cpu_stats = true;
          cpu_temp = true;
          cpu_power = true;
          #cpu_text = "CPU";
          ram = true;
          fps = true;
          vulkan_driver = true;
          gamemode = true;
          fsr = true;
          hdr = true;
          mangoapp_steam = true;
          position = "top-left";
          round_corners = 7; 
          #width = ;
          #height = ;
          table_columns = 3;
          background_alpha = 0.5;
          #pci_dev = "0:c1:00.0";
          toggle_hud = "Shift_R+F12";
        };
      };
    };

    programs = {
      coolercontrol.enable = true;

      # Better gaming performance
      # Steam: Right-click game -> Properties -> Launch options: gamemoderun %command%
      # Lutris: Preferences -> Global options -> CPU -> Enable Feral GameMode
      gamemode = {
        enable = true;
        settings.general.inhibit_screensaver = 1;
      };

      steam = {
        enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
        # Steam compositor
        gamescopeSession.enable = true;

        # Firewall related
        dedicatedServer.openFirewall = false;
        localNetworkGameTransfers.openFirewall = true;
        remotePlay.openFirewall = true;
        
        package = pkgs.steam.override {
          extraLibraries = pkgs: ( with config.hardware.opengl; if pkgs.hostPlatform.is64bit
            then [ package ] ++ extraPackages
            else [ package32 ] ++ extraPackages32
          );

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
  };
}
