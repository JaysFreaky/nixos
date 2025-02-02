{
  cfgOpts,
  inputs,
  lib,
  ...
}: let
  cfg = cfgOpts.flatpak;
in {
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  options.myOptions.flatpak.enable = lib.mkEnableOption "Flatpak";

  config = lib.mkIf (cfg.enable) {
    # https://github.com/gmodena/nix-flatpak
    services.flatpak = {
      enable = true;
      # Search package names via https://flathub.org/apps/search?q=
      packages = [
        "org.libreoffice.LibreOffice"
      ];
      remotes = [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
      ];
      update.auto = {
        enable = true;
        onCalendar = "weekly";
      };
    };
  };
}
