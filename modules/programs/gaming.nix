{ config, lib, pkgs, vars, ... }:
with lib;
{
  options.gaming.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.gaming.enable) {
    environment.systemPackages = with pkgs; [
      #coolercontrol.coolercontrold     # Fan control daemon
      #coolercontrol.coolercontrol-gui  # Fan control GUI
      corectrl                          # CPU/GPU undervolting
      #heroic                           # Game launcher
      #lutris                           # Game launcher
      #mangohud                         # FPS counter
      #moonlight-qt                     # Remote streaming
      #playonlinux                      # GUI for Windows programs
      #protonup-ng                      # CLI updater for ProtonGE
      #protonup-qt                      # GUI updater for ProtonGE
      #steam-run                        # Run commands in same environment as Steam
    ];

    environment.variables = {
      # Lutris Feral gamemode enablement
      #LD_PRELOAD = "/nix/store/*-gamemode-*-lib/lib/libgamemodeauto.so";

      # ProtonGE path - not needed with proton-ge-bin?
      #STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${vars.user}/.steam/root/compatibilitytools.d";
    };

    home-manager.users.${vars.user} = {
      programs.mangohud = {
        enable = true;
        settings = {
          #settings
        };
      };
    };

    programs = {
      coolercontrol.enable = true;

      # Better gaming performance
      # Steam: Right-click game - Properties - Launch options: gamemoderun %command%
      # Lutris: General Preferences - Enable Feral GameMode
        # - Global options - Add Environment Variables: LD_PRELOAD="/nix/store/*-gamemode-*-lib/lib/libgamemodeauto.so";
      gamemode = {
        enable = true;
        settings.general.inhibit_screensaver = 0;
      };

      # Steam compositor
      gamescope.enable = true;

      # Same as pkgs.steam/pkgs.steamPackages.steam - Used to also be pkgs.steam-original
      steam = {
        enable = true;
        dedicatedServer.openFirewall = false;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
        gamescopeSession.enable = true;
        remotePlay.openFirewall = false;

        package = pkgs.steam.override {
          extraPkgs = (pkgs: with pkgs; [
            #gamemode
            /* Don't remember what these do - Not sure if needed
            xorg.libXcursor
            xorg.libXi
            xorg.libXinerama
            xorg.libXScrnSaver
            libpng
            libpulseaudio
            libvorbis
            stdenv.cc.cc.lib
            libkrb5
            keyutils
            */
          ]);
        };
      };
    };
  };
}
