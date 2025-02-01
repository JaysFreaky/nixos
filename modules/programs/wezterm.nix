{
  cfgOpts,
  inputs,
  lib,
  myUser,
  pkgs,
  ...
}: let
  cfg = cfgOpts.wezterm;
in {
  options.myOptions.wezterm.enable = lib.mkEnableOption "Wezterm";

  config = lib.mkIf (cfg.enable) {
    home-manager.users.${myUser} = {
      programs.wezterm = {
        enable = true;
        enableBashIntegration = false;
        enableZshIntegration = false;
        package = inputs.wezterm.packages.${pkgs.system}.default;
        extraConfig = ''
          function get_appearance()
            if wezterm.gui then
              return wezterm.gui.get_appearance()
            end
            return 'Dark'
          end

          function scheme_for_appearance(appearance)
            if appearance:find 'Dark' then
              return 'tokyonight-storm'
            else
              return 'tokyonight-day'
            end
          end

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
            color_scheme = scheme_for_appearance(get_appearance()),
            xcursor_theme = xcursor_theme,
            xcursor_size = xcursor_size,
          }
        '';
      };
    };
  };
}
