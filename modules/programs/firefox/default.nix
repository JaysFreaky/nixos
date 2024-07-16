{ config, pkgs, vars, ... }:
let
  inherit (config.nur.repos.rycee) firefox-addons;
  bpc = {
    version = "3.7.4.0";
    sha256 = "sha256-PEZc4z8R1t5e3m8E5q5GWH1I+MRb48At2NM5rbrOLFA=";
  };
in {
  environment.systemPackages = with pkgs; [
    # Hardware video acceleration
    ffmpeg
  ];

  home-manager.users.${vars.user} = {
    programs.firefox = {
      enable = true;

      policies = {
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        FirefoxHome = {
          Search = false;
          TopSites = false;
          SponsoredTopSites = false;
          Highlights = false;
          Pocket = false;
          SponsoredPocket = false;
          Snippets = false;
        };
        UserMessaging = {
          WhatsNew = false;
          ExtensionRecommendations = false;
          FeatureRecommendations = false;
          UrlbarInterventions = false;
          SkipOnboarding = true;
          MoreFromMozilla = false;
        };
      };

      profiles.${vars.user} = {
        id = 0;
        isDefault = true;
        name = "${vars.name}";
        #userChrome = builtins.readFile ./userChrome.css;
        #userContent = builtins.readFile ./userContent.css;

        containers = {
          "Google" = {
            color = "red";
            icon = "fence";
            id = 1;
          };
          "Amazon" = {
            color = "yellow";
            icon = "cart";
            id = 2;
          };
          "Banking" = {
            color = "green";
            icon = "dollar";
            id = 3;
          };
        };
        containersForce = true;

        # Search extensions at: https://nur.nix-community.org/repos/rycee/
        extensions = with firefox-addons; [
          (bypass-paywalls-clean.override {   # Previous releases can be deleted, so overriding with latest version
            version = bpc.version;
            url = "https://github.com/bpc-clone/bpc_updates/releases/download/latest/bypass_paywalls_clean-${bpc.version}.xpi";
            sha256 = bpc.sha256;
          })
          canvasblocker
          darkreader
          enhancer-for-youtube
          multi-account-containers
          nighttab
          onepassword-password-manager
          simplelogin
          sponsorblock
          ublock-origin
        ];

        search = {
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
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
            };

            "Home Manager Options" = {
              definedAliases = [ "@hm" ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              urls = [{
                template = "https://home-manager-options.extranix.com/";
                params = [
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
            };

            "Nix Packages" = {
              definedAliases = [ "@np" ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              urls = [{
                template = "https://search.nixos.org/packages";
                params = [
                  { name = "type"; value = "packages"; }
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
            };

            "Nix Options" = {
              definedAliases = [ "@no" ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              urls = [{
                template = "https://search.nixos.org/options";
                params = [
                  { name = "type"; value = "options"; }
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
            };
          };
        };

        settings = import ./settings.nix { inherit config; };
      };

      profiles.vanilla = {
        id = 1;
        name = "Vanilla";
      };
    };
  };

  xdg.mime.defaultApplications = {
    "application/pdf" = [ "firefox.desktop" ];
  };

}
