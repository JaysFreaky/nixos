{
  cfgOpts,
  lib,
  pkgs,
  ...
}: let
  cfg = cfgOpts.plex;
in {
  options.myOptions.plex = {
    enable = lib.mkEnableOption "Plex";
    shortcut = with lib; mkOption {
      default = "plex-desktop.desktop";
      description = "Which desktop shortcut to use";
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
        (lib.mkIf (!cfgOpts.desktops.kde.enable) pkgs.kdePackages.xdg-desktop-portal-kde)
        (lib.mkIf (!cfgOpts.desktops.gnome.enable) pkgs.xdg-desktop-portal-gtk)
      ];
      wlr.enable = true;
      xdgOpenUsePortal = true;
    };
  };
}
