{ pkgs, vars, ... }:

{
  home-manager.users.${vars.user} = {
    # Enabling through HM adds the command to .bashrc automatically
    programs.starship.enable = true;

    xdg.configFile."starship.toml".source = ./pastel-powerline.toml;
  };
}


