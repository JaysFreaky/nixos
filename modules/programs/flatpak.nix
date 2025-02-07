{
  cfgOpts,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = cfgOpts.flatpak;
  flatseal = if (cfgOpts.desktops.gnome.enable) then "com.github.tchx84.Flatseal" else "";
in {
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  options.myOptions.flatpak.enable = lib.mkEnableOption "Flatpak";

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = (
      lib.optional (cfgOpts.desktops.gnome.enable) (with pkgs; [
        gnome-software  # Gnome store
      ])) ++ (
      lib.optional (cfgOpts.desktops.kde.enable) (with pkgs.kdePackages; [
        discover        # KDE store
        flatpak-kcm     # Flatpak KDE settings module
      ])
    );

    # https://github.com/gmodena/nix-flatpak
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
