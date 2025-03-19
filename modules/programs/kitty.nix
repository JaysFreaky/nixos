{
  cfgOpts,
  config,
  lib,
  myUser,
  pkgs,
  ...
}: let
  cfg = cfgOpts.kitty;
  stylix = config.stylix.enable;
in {
  options.myOptions.kitty.enable = lib.mkEnableOption "Kitty";

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [ pkgs.kitty-themes ];

    home-manager.users.${myUser} = {
      programs.kitty = {
        enable = true;
        extraConfig = lib.mkIf (!stylix) ''include /home/${myUser}/.config/kitty/current-theme.conf'';
        font.name = lib.mkDefault "Iosvmata";
        font.size = lib.mkDefault 14;
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
          symbol_map = "U+e000-U+e00a,U+ea60-U+ebeb,U+e0a0-U+e0c8,U+e0ca,U+e0cc-U+e0d7,U+e200-U+e2a9,U+e300-U+e3e3,U+e5fa-U+e6b1,U+e700-U+e7c5,U+ed00-U+efc1,U+f000-U+f2ff,U+f000-U+f2e0,U+f300-U+f372,U+f400-U+f533,U+f0001-U+f1af0 Symbols Nerd Font Mono";
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
