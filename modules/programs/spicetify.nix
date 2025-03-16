{
  config,
  lib,
  pkgs,
  cfgOpts,
  inputs,
  myUser,
  ...
}: let
  cfg = cfgOpts.spicetify;
  stylix = config.stylix.enable;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
in {
  imports = [ inputs.spicetify-nix.nixosModules.spicetify ];

  options.myOptions.spicetify.enable = lib.mkEnableOption "Spicetify";

  config = lib.mkIf (cfg.enable) {
    home-manager.users.${myUser} = {
      imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];

      programs.spicetify =  {
        enable = true;
        theme = spicePkgs.themes.text;
        colorScheme = "CatppuccinMocha";
        enabledExtensions = builtins.attrValues {
          inherit (spicePkgs.extensions)
            fullAlbumDate
            hidePodcasts
            savePlaylists
            wikify
          ;
        };
      };

      specialisation = lib.mkIf (stylix) {
        dark.configuration.programs.spicetify.colorScheme = lib.mkForce "CatppuccinMocha";
        light.configuration.programs.spicetify.colorScheme = lib.mkForce "CatppuccinFrappe";
      };
    };

    /*
    programs.spicetify = {
      enable = true;
      theme = spicePkgs.themes.text;
      colorScheme = "CatppuccinMocha";
      enabledExtensions = builtins.attrValues {
        inherit (spicePkgs.extensions)
          fullAlbumDate
          hidePodcasts
          savePlaylists
          wikify
        ;
      };
    };
    */
  };
}
