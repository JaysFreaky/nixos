{ config, lib, pkgs, ... }: let
  cfg = config.myOptions.plex;
  cfg-desktops = config.myOptions.desktops;
in {
  options.myOptions.plex = {
    enable = lib.mkEnableOption "Plex";
    shortcut = with lib; mkOption {
      default = "plex-desktop.desktop";
      description = "Whether to use the plex-desktop or plexmediaplayer shortcut";
      type = types.str;
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [
      plex-desktop          # Modern - plex-desktop.desktop
      #plex-media-player    # Outdated - plexmediaplayer.desktop
    ];

    xdg.portal = {
      extraPortals = [
        (lib.mkIf (!cfg-desktops.kde.enable) pkgs.kdePackages.xdg-desktop-portal-kde)
        (lib.mkIf (!cfg-desktops.gnome.enable)  pkgs.xdg-desktop-portal-gtk)
      ];
      wlr.enable = true;
      xdgOpenUsePortal = true;
    };

  };
}
