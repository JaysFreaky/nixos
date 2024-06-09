{ pkgs, vars, ... }: {
  home-manager.users.${vars.user} = {
    gtk = {
      enable = true;

      cursorTheme = {
        # Variants: Bibata-(Modern/Original)-(Amber/Classic/Ice)
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        # Sizes: 16 20 22 24 28 32 40 48 56 64 72 80 88 96
        size = 24;
      };

      iconTheme = {
        # Variants: Papirus Papirus-Dark Papirus-Light
        name = "Papirus";
        # Folder color variants: https://github.com/PapirusDevelopmentTeam/papirus-folders
        # adwaita black blue bluegrey breeze brown carmine cyan darkcyan deeporange
        # green grey indigo magenta nordic orange palebrown paleorange pink red
        # teal violet white yaru yellow
        package = pkgs.papirus-icon-theme.override { color = "violet"; };
      };

   /* theme = {
        name = "";
        package = "";
      }; */
    };
  };

}
