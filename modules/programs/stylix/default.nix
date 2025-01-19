{
  cfgOpts,
  inputs,
  lib,
  pkgs,
  vars,
  ...
}: let
  cfg = cfgOpts.stylix;

  base16 = "${pkgs.base16-schemes}/share/themes";
  theme = {
    dark = cfg.theme.dark;
    light = cfg.theme.light;
  };
  wallpaper = {
    dark = cfg.wallpaper.dark;
    light = cfg.wallpaper.light;
  };
in {
  imports = [ inputs.stylix.nixosModules.stylix ];

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
          name = "JetBrainsMonoNL Nerd Font Mono";
          package = pkgs.nerd-fonts.jetbrains-mono;
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
        bat.enable = true;
        btop.enable = true;
        #hyprland.enable = true;
        #kde.enable = true;
        kitty.enable = true;
        #mako.enable = true;
        mangohud.enable = true;
        neovim = {
          enable = true;
          transparentBackground.main = true;
        };
        #rofi.enable = true;
        # Disabling Spicetify to troubleshoot
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
