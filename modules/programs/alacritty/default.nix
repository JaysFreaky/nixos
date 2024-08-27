{ config, lib, vars, ... }: let
  cfg = config.myOptions.alacritty;
in {
  options.myOptions.alacritty.enable = lib.mkEnableOption "Alacritty";

  config = lib.mkIf (cfg.enable) {
    home-manager.users.${vars.user} = {
      programs.alacritty = with lib; {
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
