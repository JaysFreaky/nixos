{ config, lib, vars, ... }: with lib; {
  options.kitty.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.kitty.enable) {
    home-manager.users.${vars.user} = {
      programs.kitty = {
        enable = true;
        font.name = mkDefault "JetBrainsMono Nerd Font Mono";
        font.size = mkDefault 12;

        settings = {
          # Blur not supported in GNOME
          background_blur = 10;
          background_opacity = mkDefault "0.8";
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
      };
    };
  };

}
