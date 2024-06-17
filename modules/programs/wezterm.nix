{ config, inputs, lib, pkgs, vars, ... }: with lib; {
  options.wezterm.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.wezterm.enable) {
    home-manager.users.${vars.user} = {
      programs.wezterm = {
        enable = true;
        package = inputs.wezterm.packages.${pkgs.system}.default;
        #extraConfig = '''';
      };
    };
  };

}
