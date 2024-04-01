{ config, lib, pkgs, vars, ... }:
with lib;
let
  # https://github.com/alacritty/alacritty-theme
  theme = ./tokyo-night-storm.toml;
in {
  options.alacritty.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.alacritty.enable) {
    home-manager.users.${vars.user} = {
      programs.alacritty = {
        enable = true;

        settings = {
          # Import Pywal wallpaper color theming
          #import = [ "/home/${vars.user}/.cache/wal/colors-alacritty.toml" ];
          import = [ "/home/${vars.user}/.config/alacritty/theme.toml" ];

          mouse.hide_when_typing = false;
          selection.save_to_clipboard = true;

          font = {
            normal = {
              family = "JetBrainsMono Nerd Font";
              style = "Regular";
            };
            size = 12;
          };

          window = {
            blur = true;
            opacity = 0.8;
          };
        };
      };

      # Create alacritty pywal template
      xdg.configFile."wal/templates/colors-alacritty.toml".source = ./colors-alacritty.toml;
      # Create theme color toml
      xdg.configFile."alacritty/theme.toml".source = theme;
    };
  };
}


