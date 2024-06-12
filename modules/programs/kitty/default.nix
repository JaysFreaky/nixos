{ config, lib, vars, ... }: with lib; {
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
          # Blur not supported in GNOME
          background_blur = 10;
          background_opacity = "0.80";
          confirm_os_window_close = 0;
          copy_on_select = "clipboard";
          enable_audio_bell = "no";
          linux_display_server = "wayland";
          tab_bar_edge = "top";
          tab_bar_style = "powerline";
          tab_powerline_style = "angled";
          touch_scroll_multiplier = "2.0";
          wayland_titlebar_color = "system";
        };

        extraConfig = ''
          # Import Pywal wallpaper color theming
          #include /home/${vars.user}/.cache/wal/colors-kitty.conf

          # Import symbolically-linked theme
          include /home/${vars.user}/.config/kitty/current-theme.conf
        '';
      };
    };
  };

}
