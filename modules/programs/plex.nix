{
  lib,
  pkgs,
  cfgOpts,
  ...
}: let
  cfg = cfgOpts.plex;
in {
  options.myOptions.plex.enable = lib.mkEnableOption "Plex";

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [ pkgs.plex-desktop ];

    # Required for initial login link
      # Can be bypassed by 'set NIXOS_XDG_OPEN_USE_PORTAL=1' and then unsetting when finished
    #xdg.portal.xdgOpenUsePortal = true;
  };
}
