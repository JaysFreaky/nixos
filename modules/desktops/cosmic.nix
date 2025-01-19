{
  cfgOpts,
  config,
  inputs,
  lib,
  pkgs,
  vars,
  ...
}: let
  cfg = cfgOpts.desktops.cosmic;

  cursor = {
    # Variants: Bibata-(Modern/Original)-(Amber/Classic/Ice)
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    # Sizes: 16 20 22 24 28 32 40 48 56 64 72 80 88 96
    size = 24;
  };
  icon = {
    # Variants: Papirus Papirus-Dark Papirus-Light
    name = "Papirus";
    # Folder color variants: https://github.com/PapirusDevelopmentTeam/papirus-folders
    # adwaita black blue bluegrey breeze brown carmine cyan darkcyan deeporange
    # green grey indigo magenta nordic orange palebrown paleorange pink red
    # teal violet white yaru yellow
    package = pkgs.papirus-icon-theme.override { color = "violet"; };
  };
  profileImg = ../../assets/profile.png;
  wallpaper = {
    day = "${vars.configPath}/assets/wallpapers/blobs-l.png";
    night = "${vars.configPath}/assets/wallpapers/blobs-d.png";
  };
in {
  imports = [ inputs.nixos-cosmic.nixosModules.default ];

  options.myOptions.desktops.cosmic.enable = lib.mkEnableOption "Cosmic desktop";

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [
      cursor.package              # For GDM login screen
      icon.package                # Icon theme
      libsecret                   # Secret storage used by gnome-keyring / KDE-wallet
      neovide                     # GUI launcher for neovim
    ];

    services = {
      desktopManager.cosmic.enable = true;
      displayManager.cosmic-greeter.enable = true;

      xserver = {
        enable = true;
        excludePackages = with pkgs; [ xterm ];
      };
    };

    home-manager.users.${vars.user} = {
      # Sets profile image
      home.file.".face".source = profileImg;

      # Set default application file associations
      xdg.mimeApps = let
        mime = {
          archive = [ "org.gnome.FileRoller.desktop" ];
          audio = [ "com.system76.CosmicPlayer.desktop" ];
          calendar = [ "" ];
          image = [ "org.gnome.eog.desktop" ];
          pdf = [ "org.gnome.Evince.desktop" ];
          text = [
            "com.system76.CosmicEdit.desktop"
            #"neovide.desktop"
          ];
          video = [ "com.system76.CosmicPlayer.desktop" ];
        };
      in {
        enable = false;
        associations.added = config.xdg.mimeApps.defaultApplications;
        defaultApplications = import ./mimeapps.nix { inherit mime; };
      };
    };
  };
}
