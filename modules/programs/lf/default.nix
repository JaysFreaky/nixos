{
  pkgs,
  myUser,
  ...
}: {
  environment.systemPackages = with pkgs; [
  # Previewer tools
    # Archive
    atool

    # Audio / Video
    ffmpegthumbnailer    # Video thumbnails

    #devour               # Hide lf window before displaying image - x only?
    #feh                   # Image viewer
    #sxiv                 # Image viewer
  ];

  home-manager.users.${myUser} = {
    programs.lf = {
      enable = true;

      # https://github.com/NikitaIvanovV/ctpv
      previewer = {
        keybinding = "i";
        source = "${pkgs.ctpv}/bin/ctpv";
      };

      extraConfig = ''
        &${pkgs.ctpv}/bin/ctpv -s $id
        cmd on-quit %${pkgs.ctpv}/bin/ctpv -e $id
        set cleaner ${pkgs.ctpv}/bin/ctpvclear
      '';
/*
      extraConfig =
        let
          previewer = pkgs.writeShellScriptBin "kitty_preview.sh" ''
            file=$1
            w=$2
            h=$3
            x=$4
            y=$5

            if [[ "$( ${pkgs.file}/bin/file -Lb --mime-type "$file")" =~ ^image ]]; then
              ${pkgs.kitty}/bin/kitty +kitten icat --silent --stdin no --transfer-mode file --place "''${w}x''${h}@''${x}x''${y}" "$file" < /dev/null > /dev/tty
              exit 1
            fi

            ${pkgs.pistol}/bin/pistol "$file"
          '';

          cleaner = pkgs.writeShellScriptBin "kitty_clean.sh" ''
            ${pkgs.kitty}/bin/kitty +kitten icat --clear --stdin no --silent --transfer-mode file < /dev/null > /dev/tty
          '';
        in
        ''
          set cleaner ${cleaner}/bin/kitty_clean.sh
          set previewer ${previewer}/bin/kitty_preview.sh
      '';
*/
    };

    xdg.configFile."lf/icons".source = ./icons;
  };
}
