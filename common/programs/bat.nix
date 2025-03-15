{
  pkgs,
  myUser,
  ...
}: {
  home-manager.users.${myUser}.programs.bat = {
    enable = true;
    extraPackages = builtins.attrValues {
      inherit (pkgs.bat-extras)
        batdiff
        batgrep
        batman
        batpipe
        batwatch
        prettybat
      ;
    };
  };
}
