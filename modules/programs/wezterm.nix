{
  config,
  lib,
  pkgs,
  cfgOpts,
  inputs,
  myUser,
  ...
}: let
  cfg = cfgOpts.wezterm;
  stylix = config.stylix.enable;

  dark = "Catppuccin Mocha";
  light = "Catppuccin Frappe";
in {
  options.myOptions.wezterm.enable = lib.mkEnableOption "Wezterm";

  config = lib.mkIf (cfg.enable) {
    home-manager.users.${myUser}.programs.wezterm = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = false;
      package = inputs.wezterm.packages.${pkgs.system}.default;
      extraConfig = ''
        local xcursor_size = nil
        local xcursor_theme = nil

        local success, stdout, stderr = wezterm.run_child_process({"gsettings", "get", "org.gnome.desktop.interface", "cursor-theme"})
        if success then
          xcursor_theme = stdout:gsub("'(.+)'\n", "%1")
        end

        local success, stdout, stderr = wezterm.run_child_process({"gsettings", "get", "org.gnome.desktop.interface", "cursor-size"})
        if success then
          xcursor_size = tonumber(stdout)
        end

        return {
          xcursor_theme = xcursor_theme,
          xcursor_size = xcursor_size,
        }
      '' ++ lib.optional (!stylix) ''
        function get_appearance()
          if wezterm.gui then
            return wezterm.gui.get_appearance()
          end
          return 'Dark'
        end

        function scheme_for_appearance(appearance)
          if appearance:find 'Dark' then
            return '${dark}'
          else
            return '${light}'
          end
        end

        return {
          color_scheme = scheme_for_appearance(get_appearance()),
        }
      '';
    };
  };
}
