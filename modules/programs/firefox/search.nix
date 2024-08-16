{ pkgs, ... }: {
  default = "Startpage";
  force = true;
  privateDefault = "Google";

  engines = {
    "Startpage" = {
      definedAliases = [ "@sp" ];
      icon = "https://www.startpage.com/sp/cdn/favicons/favicon--default.ico";
      urls = [{
        template = "https://www.startpage.com/sp/search";
        params = [
          {
            name = "query";
            value = "{searchTerms}";
          }
        ];
      }];
    };

    "Home Manager Options" = {
      definedAliases = [ "@hm" ];
      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      urls = [{
        template = "https://home-manager-options.extranix.com/";
        params = [
          {
            name = "query";
            value = "{searchTerms}";
          }
        ];
      }];
    };

    "Nix Packages" = {
      definedAliases = [ "@np" ];
      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      urls = [{
        template = "https://search.nixos.org/packages";
        params = [
          {
            name = "channel";
            value = "unstable";
          }
          {
            name = "type";
            value = "packages";
          }
          {
            name = "query";
            value = "{searchTerms}";
          }
        ];
      }];
    };

    "NixOS Options" = {
      definedAliases = [ "@no" ];
      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      urls = [{
        template = "https://search.nixos.org/options";
        params = [
          {
            name = "channel";
            value = "unstable";
          }
          {
            name = "type";
            value = "options";
          }
          {
            name = "query";
            value = "{searchTerms}";
          }
        ];
      }];
    };

    "NixOS Wiki" = {
      definedAliases = [ "@nw" ];
      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      urls = [{
        template = "https://wiki.nixos.org/wiki/{searchTerms}";
      }];
    };
  };

}
