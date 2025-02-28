{
  lib,
  pkgs,
  cfgOpts,
  inputs,
  ...
}: let
  cfg = cfgOpts.flatpak;
  flatseal = lib.mkIf (cfgOpts.desktops.gnome.enable) "com.github.tchx84.Flatseal";
in {
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  options.myOptions.flatpak.enable = lib.mkEnableOption "Flatpak";

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = (
      lib.optional (cfgOpts.desktops.gnome.enable) [
        pkgs.gnome-software             # Gnome store
      ]
    ) ++ (
      lib.optional (cfgOpts.desktops.kde.enable) [
        pkgs.kdePackages.discover       # KDE store
        pkgs.kdePackages.flatpak-kcm    # Flatpak KDE settings module
      ]
    );

    services.flatpak = {
      enable = true;
      # Search package names via https://flathub.org/apps/search?q=
      packages = [
        flatseal
        #"org.libreoffice.LibreOffice"
      ];
      # Flathub added by default
      remotes = [{
        #name = "flathub";
        #location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }];
      uninstallUnmanaged = false;
      update.auto = {
        enable = true;
        onCalendar = "weekly";
      };
    };
  };
}
