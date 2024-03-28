{ config, lib, pkgs, vars, ... }:
with lib;
{
  options.kitty.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.kitty.enable) {
    home-manager.users.${vars.user} = {
      programs.kitty = {
        enable = true;
        font.name = "JetBrainsMono Nerd Font";
        font.size = 12;

        settings = {
          background_blur = 10;
          background_opacity = "0.75";
          confirm_os_window_close = 0;
          enable_audio_bell = "no";
          tab_bar_edge = "top";
          tab_bar_style = "powerline";
          tab_powerline_style = "angled";
          touch_scroll_multiplier = "2.0";
        };

        # Import Pywal wallpaper color theming
    /*  extraConfig = ''
          #include /home/${vars.user}/.cache/wal/colors-kitty.conf
        ''; */
      };
    };
  };
}


