{ vars, ... }: {
  home-manager.users.${vars.user} = {
    # Enabling through HM adds the command to .bashrc automatically
    programs.starship.enable = true;

    # Import theme file(s)
    xdg.configFile."starship.toml".source = ./gruvbox-rainbow.toml;
  };
}
