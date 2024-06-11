{ vars, ... }: {
  home-manager.users.${vars.user} = {
    programs.bash = {
      enable = true;

      initExtra = ''
      '';

      shellAliases = {
        ".." = "cd ..";
        ".df" = "cd /persist/etc/nixos";
        "ff" = "fastfetch";
        "fishies" = "asciiquarium";
        "ga" = "git add";
        "gc" = "git commit";
        "gd" = "git diff";
        "gs" = "git status";
        "ll" = "ls -la";
        "spf" = "superfile";
      };
    };
  };

}
