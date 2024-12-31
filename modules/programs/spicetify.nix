{ config, inputs, lib, pkgs, vars, ... }: let
  cfg = config.myOptions.spicetify;
  stylix = config.stylix.enable;

  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
in {
  imports = [ inputs.spicetify-nix.nixosModules.spicetify ];

  options.myOptions.spicetify.enable = lib.mkEnableOption "Spicetify";

  config = lib.mkIf (cfg.enable) {
    home-manager.users.${vars.user} = {
      imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];

      programs.spicetify =  {
        enable = true;
        theme = spicePkgs.themes.text;
        colorScheme = "CatppuccinMocha";
        enabledExtensions = with spicePkgs.extensions; [
          fullAlbumDate
          hidePodcasts
          savePlaylists
          wikify
        ];
      };

      specialisation = lib.mkIf (stylix) {
        dark.configuration.programs.spicetify.colorScheme = lib.mkForce "CatppuccinMocha";
        light.configuration.programs.spicetify.colorScheme = lib.mkForce "CatppuccinLatte";
      };
    };

    /*programs.spicetify = {
      enable = true;
      theme = spicePkgs.themes.text;
      colorScheme = "CatppuccinMacchiato";
      enabledExtensions = with spicePkgs.extensions; [
        fullAlbumDate
        hidePodcasts
        savePlaylists
        wikify
      ];
    };*/

  };
}
