{ config, lib, pkgs, vars, ... }: let
  cfg = config.myOptions.stylix;

  base16 = "${pkgs.base16-schemes}/share/themes";
  theme = {
    dark = config.myOptions.stylix.theme.dark;
    light = config.myOptions.stylix.theme.light;
  };
  wallpaper = {
    dark = config.myOptions.stylix.wallpaper.dark;
    light = config.myOptions.stylix.wallpaper.light;
  };
in {
  options.myOptions.stylix = with lib; {
    enable = mkEnableOption "Stylix";
    theme = {
      dark = mkOption {
        default = "catppuccin-macchiato.yaml";
        description = "The theme's file name located within 'base16-schemes/share/themes/'.";
        example = "catppuccin-macchiato.yaml";
        type = types.str;
      };
      light = mkOption {
        default = "catppuccin-latte.yaml";
        description = "The theme's file name located within 'base16-schemes/share/themes/'.";
        example = "catppuccin-latte.yaml";
        type = types.str;
      };
    };
    wallpaper = {
      dark = mkOption {
        default = "${pkgs.gnome-backgrounds}/share/backgrounds/gnome/amber-d.jxl";
        description = "File path to choosen wallpaper.";
        example = "/path/to/file.ext";
        type = types.str;
      };
      light = mkOption {
        default = "${pkgs.gnome-backgrounds}/share/backgrounds/gnome/amber-l.jxl";
        description = "File path to choosen wallpaper.";
        example = "/path/to/file.ext";
        type = types.str;
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    stylix = {
      enable = true;
      autoEnable = false;

      base16Scheme = lib.mkDefault "${base16}/${theme.dark}";

      cursor = {
        # Variants: Bibata-(Modern/Original)-(Amber/Classic/Ice)
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        # Sizes: 16 20 22 24 28 32 40 48 56 64 72 80 88 96
        size = 24;
      };

      fonts = {
        monospace = {
          name = "JetBrainsMono Nerd Font Mono";
          package = pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; };
        };
        sizes = {
          #applications = 12;
          #desktop = 10;
          #popups = 10;
          terminal = 12;
        };
      };

      image = lib.mkDefault "${wallpaper.dark}";

      opacity = {
        #applications = 1.0;
        #desktop = 1.0;
        #popups = 1.0;
        terminal = 0.9;
      };

      polarity = lib.mkDefault "dark";

      targets = {
        console.enable = true;
        #gnome.enable = false;
        gtk.enable = true;
        #regreet.enable = false;
      };
    };

    home-manager.users.${vars.user} = {
      stylix.targets = {
        alacritty.enable = true;
        #bat.enable = true;
        #btop.enable = true;
        #hyprland.enable = true;
        #kde.enable = true;
        kitty.enable = true;
        #mako.enable = true;
        #mangohud.enable = true;
        neovim = {
          #enable = true;
          #transparentBackground.main = true;
        };
        #rofi.enable = true;
        #spicetify.enable = true;
        #tmux.enable = true;
        #waybar.enable = true;
        #wezterm.enable = true;
        #wofi.enable = true;
        #zellij.enable = true;
      };

      specialisation = {
        dark.configuration = {
          stylix = {
            base16Scheme = "${base16}/${theme.dark}";
            image = "${wallpaper.dark}";
            polarity = lib.mkForce "dark";
          };
        };
        light.configuration = {
          stylix = {
            base16Scheme = "${base16}/${theme.light}";
            image = "${wallpaper.light}";
            polarity = lib.mkForce "light";
          };
        };
      };
    };

  };
}
