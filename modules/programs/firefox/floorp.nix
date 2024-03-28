{ pkgs, vars, ... }:

{
  home-manager.users.${vars.user} = {
    # Use Firefox profiles for Floorp configuration until better integration with HM
    # Requires the use of --impure during rebuild - not ideal

    # Profile folder
    home.file.".floorp/default" = {
      recursive = true;
      source = "/home/${vars.user}/.mozilla/firefox/default";
    };

    # profiles.ini
    home.file.".floorp/profiles.ini".text = ''
      [Profile0]
      Name=default
      IsRelative=1
      Path=default
      Default=1

      [General]
      StartWithLastProfile=1
      Version=2
    '';

    # Enable Firefox/Floorp
    programs.firefox = {
      enable = true;
      package = pkgs.floorp;

      profiles.default = {
        id = 0;
        settings = {
          # Disable pinch to zoom
          "apz.gtk.touchpad_pinch.enabled" = false;

          # Force hardware decoding
          "gfx.webrender.all" = true;
          "media.ffmpeg.vaapi.enabled" = true;

          # Fix Wayland video flickering issue - here just in case
          #"widget.wayland.opaque-region.enabled" = false;

          # XDG Portal integration
          "widget.use-xdg-desktop-portal.file-picker" = 1;
        };
      };
    };
  };
}


