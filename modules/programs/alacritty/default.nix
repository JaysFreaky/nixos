{ config, lib, pkgs, vars, ... }:
with lib;
{
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
          # https://github.com/alacritty/alacritty-theme
          import = [ "/home/${vars.user}/.config/alacritty/tokyo-night-storm.toml" ];

          mouse.hide_when_typing = true;
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
      xdg.configFile."alacritty/tokyo-night-storm.toml".source = ./tokyo-night-storm.toml;
    };
  };
}


