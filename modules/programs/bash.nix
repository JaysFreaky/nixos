{ vars, ... }: {
  home-manager.users.${vars.user} = {
    programs.bash = {
      enable = true;

      # This is causing issues with GNOME's night switcher extension:
      # Probably fine on Hyprland
      #if command -v wal > /dev/null 2>&1 && [ "$TERM" = "alacritty" ]; then
          #wal -Rqe
      #fi
      initExtra = ''
      '';

      shellAliases = {
        ".." = "cd ..";
        ".df" = "cd /persist/etc/nixos";
        "ff" = "fastfetch";
        "fishies" = "asciiquarium";
        "gd" = "git diff";
        "gs" = "git status";
        "ll" = "ls -la";
      };
    };
  };

}

