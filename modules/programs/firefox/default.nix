{ config, lib, pkgs, vars, ... }: let
  browser = config.myOptions.browser;

  bpc = {
    commit = "d2be9765457e4d8e17c49d30628a17da88e6fb5f";
    sha256 = "sha256-h/T76AZYOWUnrb/N9yDLWl0H6sxODArXP2dU0OIDijw=";
    version = "3.9.6.0";
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
      programs.${browser} = {
        enable = true;

        policies = {
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableTelemetry = true;
          #ExtensionUpdate = false;
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
            bpc-pkg = bypass-paywalls-clean.override {
              version = "${bpc.version}";
              url = "https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass_paywalls_clean-${bpc.version}.xpi&inline=false&commit=${bpc.commit}";
              sha256 = "${bpc.sha256}";
            };
          in [
            augmented-steam
            bpc-pkg                       # Previous releases get deleted regularly
            canvasblocker
            darkreader
            enhancer-for-youtube
            multi-account-containers
            onepassword-password-manager
            proton-vpn
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
