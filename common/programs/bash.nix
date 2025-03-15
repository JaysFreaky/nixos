{
  myUser,
  nixPath,
  ...
}: {
  home-manager.users.${myUser}.programs.bash = {
    enable = true;
    #initExtra = '''';
    shellAliases = {
      ".." = "cd ..";
      ".df" = "cd ${nixPath}";
      "bonsai" = "cbonsai --screensaver";
      "exifinfo" = "exiftool -a -g -s \"$@\"";
      "exifstrip" = "exiftool -All= \"$@\"";
      "ff" = "fastfetch";
      "fishy" = "asciiquarium";
      "ga" = "git add";
      "gc" = "git commit";
      "gd" = "git diff";
      "gs" = "git status";
      "ll" = "ls -la";
      "nixdiff" = "nixos-rebuild build && nix store diff-closures /run/current-system ./result";
      "ns" = "nix search nixpkgs#\"$1\"";
      "spf" = "superfile";
    };
  };
}
