{ config, lib, pkgs, vars, ... }:
with lib;
{
  options.flatpak.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.flatpak.enable) {
    services.flatpak = {
      enable = true;

      # https://github.com/gmodena/nix-flatpak
      # Search package names via https://flathub.org/apps/search?q=
      packages = [
        #"org.libreoffice.LibreOffice"
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
