{
  myUser,
  ...
}: {
  home-manager.users.${myUser} = {
    # Adds the command to .bashrc automatically
    programs.starship.enable = true;

    # Import theme file(s)
    xdg.configFile."starship.toml".source = ./gruvbox-rainbow.toml;
  };
}
