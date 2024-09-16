{ config, lib, pkgs, vars, ... }: let
  browser = config.myOptions.browser;

  bpc = {
    version = "3.8.4.0";
    sha256 = "sha256-b9TvyOqnp4XZt6InW3atMuM11JP8LtrYv1ERby+i3EU=";
    #sha256 = lib.fakeHash;
  };
  firefox-addons = pkgs.nur.repos.rycee.firefox-addons;
  myAddons = pkgs.callPackage ./addons.nix {
    inherit (pkgs.nur.repos.rycee.firefox-addons) buildFirefoxXpiAddon;
  };
in {
  options.myOptions.browser = with lib; mkOption {
    default = "floorp";
    description = "Whether to use the Firefox or Floorp Home-Manager option";
    type = types.str;
  };

  config = {
    home-manager.users.${vars.user} = {
      imports = [ ./floorp-hm.nix ];

      programs.${browser} = {
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
          containers = import ./containers.nix;
          containersForce = true;
          id = 0;
          isDefault = true;
          name = "${vars.name}";
          search = import ./search.nix { inherit pkgs; };
          settings = import ./settings.nix { inherit config; };
          #userChrome = builtins.readFile ./userChrome.css;
          #userContent = builtins.readFile ./userContent.css;

          # Search extensions at: https://nur.nix-community.org/repos/rycee/
          extensions = with firefox-addons; let
            bpc-pkg = bypass-paywalls-clean.override rec {
              version = "${bpc.version}";
              url = "https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass_paywalls_clean-${version}.xpi";
              sha256 = "${bpc.sha256}";
            };
          in [
            bpc-pkg                         # Previous releases get deleted, so overriding with latest version
            canvasblocker
            darkreader
            enhancer-for-youtube
            multi-account-containers
            onepassword-password-manager
            simplelogin
            sponsorblock
            tabliss
            ublock-origin
          ] ++ (with myAddons; [
            ttv-lol-pro
          ]);
        };

        profiles.vanilla = {
          id = 1;
          name = "Vanilla";
        };
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "application/pdf" = [ "${browser}.desktop" ];
        };
      };
    };

  };
}
