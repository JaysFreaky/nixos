{ config, lib, pkgs, vars, ... }: let
  cfg = config.myOptions.kitty;
  stylix = config.stylix.enable;
in {
  options.myOptions.kitty.enable = lib.mkEnableOption "Kitty";

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [ pkgs.kitty-themes ];
    home-manager.users.${vars.user} = {
      programs.kitty = {
        enable = true;
        extraConfig = lib.mkIf (!stylix) ''include /home/${vars.user}/.config/kitty/current-theme.conf'';
        font.name = lib.mkDefault "JetBrainsMonoNL Nerd Font Mono";
        font.size = lib.mkDefault 12;

        settings = {
          # Blur not supported in GNOME
          #background_blur = 1;
          background_opacity = lib.mkDefault "0.9";
          confirm_os_window_close = 0;
          copy_on_select = "clipboard";
          #dim_opacity = "0.4";
          dynamic_background_opacity = "yes";
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
