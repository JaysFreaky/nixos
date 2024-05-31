{ config, lib, vars, ... }: with lib; {
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

          # Import symbolically-linked theme
          import = [ "/home/${vars.user}/.config/alacritty/theme.toml" ];

          live_config_reload = true;

          font = {
            size = 12;
            normal = {
              family = "JetBrainsMono Nerd Font";
              style = "Regular";
            };
          };

          mouse.hide_when_typing = false;
          selection.save_to_clipboard = true;

          window = {
            blur = true;
            opacity = 0.8;
            startup_mode = "Maximized";
          };
        };
      };

      # Create alacritty pywal template
      xdg.configFile."wal/templates/colors-alacritty.toml".source = ./colors-alacritty.toml;

      # Create theme color toml(s)
      # https://github.com/alacritty/alacritty-theme
      #xdg.configFile."alacritty/gruvbox-dark.toml".source = ./gruvbox-dark.toml;
      #xdg.configFile."alacritty/gruvbox-light.toml".source = ./gruvbox-light.toml;
      #xdg.configFile."alacritty/tokyo-night.toml".source = ./tokyo-night.toml;
      #xdg.configFile."alacritty/tokyo-night-storm.toml".source = ./tokyo-night-storm.toml;
    };
  };

}
