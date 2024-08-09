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
          live_config_reload = true;

          font = {
            size = mkDefault 12;
            normal = {
              family = mkDefault "JetBrainsMono Nerd Font Mono";
              style = mkDefault "Regular";
            };
          };

          mouse.hide_when_typing = false;
          selection.save_to_clipboard = true;

          window = {
            blur = true;
            opacity = mkDefault 0.8;
            startup_mode = "Maximized";
          };
        };
      };

      # Create alacritty pywal template
      xdg.configFile."wal/templates/colors-alacritty.toml".source = ./colors-alacritty.toml;
    };
  };

}
