{
  myUser,
  nixPath,
  ...
}: {
  home-manager.users.${myUser} = {
    programs.bash = {
      enable = true;
      #initExtra = '''';
      shellAliases = {
        ".." = "cd ..";
        ".df" = "cd ${nixPath}";
        "ff" = "fastfetch";
        "fishies" = "asciiquarium";
        "ga" = "git add";
        "gc" = "git commit";
        "gd" = "git diff";
        "gs" = "git status";
        "ll" = "ls -la";
        "nixdiff" = "nixos-rebuild build && nix store diff-closures /run/current-system ./result";
        "ns" = "nix search nixpkgs#\"$@\"";
        "spf" = "superfile";
      };
    };
  };
}
