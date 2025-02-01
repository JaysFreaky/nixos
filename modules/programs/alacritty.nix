{
  cfgOpts,
  config,
  lib,
  myUser,
  pkgs,
  ...
}: let
  cfg = cfgOpts.alacritty;
  stylix = config.stylix.enable;
in {
  options.myOptions.alacritty.enable = lib.mkEnableOption "Alacritty";

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [ pkgs.alacritty-theme ];

    home-manager.users.${myUser} = {
      programs.alacritty = {
        enable = true;
        settings = {
          font = {
            size = lib.mkDefault 12;
            normal = {
              family = lib.mkDefault "JetBrainsMono Nerd Font Mono";
              style = lib.mkDefault "Regular";
            };
          };
          import = lib.mkIf (!stylix) [ "/home/${myUser}/.config/alacritty/current-theme.toml" ];
          live_config_reload = true;
          mouse.hide_when_typing = false;
          selection.save_to_clipboard = true;
          window = {
            blur = true;
            opacity = lib.mkDefault 0.8;
            startup_mode = "Maximized";
          };
        };
      };

      # Create alacritty pywal template
      xdg.configFile."wal/templates/colors-alacritty.toml".text = ''
        [colors.primary]
        background = "{background}"
        foreground = "{foreground}"

        [colors.cursor]
        text =    "CellForeground"
        cursor =  "{cursor}"

        [colors.bright]
        black =   "{color0}"
        red =     "{color1}"
        green =   "{color2}"
        yellow =  "{color3}"
        blue =    "{color4}"
        magenta = "{color5}"
        cyan =    "{color6}"
        white =   "{color7}"

        [colors.normal]
        black =   "{color8}"
        red =     "{color9}"
        green =   "{color10}"
        yellow =  "{color11}"
        blue =    "{color12}"
        magenta = "{color13}"
        cyan =    "{color14}"
        white =   "{color15}"
      '';
    };
  };
}
